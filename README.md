# Problemas encontrados durante la práctica

Durante la práctica he tenido varios problemas que he corregido:

 1. Jenkins no arrancaba: El servicio no arrancaba porque el puerto 8080 ya estaba siendo usado por otro proceso.
 2.  Jenkins no encontraba el Dockerfile: La primera versión del pipeline intentaba usar el Dockerfile antes de haber hecho el checkout del repositorio.
 3.  Error de permisos de npm: Al ejecutar npm install dentro del contenedor, npm intentaba usar una caché en /.npm y fallaba por permisos.
 4.  Ajuste de Jenkins con Docker: Fue necesario asegurarse de que Jenkins tuviera permisos para usar Docker en el sistema.

---

# Versiones del Jenkinsfile: 

## Primera versión
``` groovy
pipeline {
    agent {
        dockerfile {
            filename 'Dockerfile'
            dir '.'
            reuseNode true
        }
    }

    options {
        skipDefaultCheckout(true)
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    triggers {
        pollSCM('H/5 * * * *')
    }

    parameters {
        string(
            name: 'MD_FILE',
            defaultValue: 'slides/presentacion.md',
            description: 'Ruta del archivo Markdown a procesar'
        )
    }

    stages {
        stage('Checkout desde SCM') {
            steps {
                checkout scm
            }
        }

        stage('Instalación de dependencias') {
            steps {
                sh '''
                    node --version
                    npm --version
                    npm install --no-save @marp-team/marp-cli
                '''
            }
        }

        stage('Generación del PDF') {
            steps {
                sh '''
                    if [ ! -f "${MD_FILE}" ]; then
                        echo "ERROR: no existe el archivo ${MD_FILE}"
                        exit 1
                    fi

                    mkdir -p pdf
                    nombre_pdf=$(basename "${MD_FILE}" .md)

                    npx @marp-team/marp-cli "${MD_FILE}" --pdf --allow-local-files -o "pdf/${nombre_pdf}.pdf"

                    ls -lh pdf
                '''
            }
        }

        stage('Archivado del artefacto') {
            steps {
                archiveArtifacts artifacts: 'pdf/*.pdf', fingerprint: true, onlyIfSuccessful: true
            }
        }
    }

    post {
        success {
            echo 'PDF generado y archivado correctamente.'
        }
        failure {
            echo 'La ejecución ha fallado.'
        }
        always {
            echo 'Fin del pipeline.'
        }
    }
}
```

Esta primera versión falló porque Jenkins intentaba construir el agente Docker usando el Dockerfile antes de haber hecho el checkout del repositorio. Observando los logs, me encontré con:

java.nio.file.NoSuchFileException: /var/lib/jenkins/workspace/pdf-marp-pipeline/Dockerfile.

Había que hacer primero el checkout del repositorio y solo después usar el Dockerfile como agente del stage que genera el PDF.


---


## Segunda versión
``` groovy
pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    triggers {
        pollSCM('H/5 * * * *')
    }

    parameters {
        string(
            name: 'MD_FILE',
            defaultValue: 'slides/presentacion.md',
            description: 'Ruta del archivo markdown a procesar'
        )
    }

    stages {
        stage('Checkout desde SCM') {
            steps {
                checkout scm
                sh 'ls -la'
            }
        }

        stage('Instalación de dependencias y generación del PDF') {
            agent {
                dockerfile {
                    filename 'Dockerfile'
                    dir '.'
                    reuseNode true
                }
            }
            steps {
                sh '''
                    node --version
                    npm --version

                    if [ ! -f "${MD_FILE}" ]; then
                        echo "ERROR: no existe el archivo ${MD_FILE}"
                        exit 1
                    fi

                    npm install --no-save @marp-team/marp-cli

                    mkdir -p pdf
                    nombre_pdf=$(basename "${MD_FILE}" .md)

                    npx @marp-team/marp-cli "${MD_FILE}" --pdf --allow-local-files -o "pdf/${nombre_pdf}.pdf"

                    ls -lh pdf
                '''
            }
        }

        stage('Archivado del artefacto') {
            steps {
                archiveArtifacts artifacts: 'pdf/*.pdf', fingerprint: true, onlyIfSuccessful: true
            }
        }
    }

    post {
        success {
            echo 'PDF generado y archivado correctamente.'
        }
        failure {
            echo 'La ejecución ha fallado.'
        }
        always {
            echo 'Fin del pipeline.'
        }
    }
}

```
En esta versión se cambió la estructura del pipeline:

El pipeline pasó a usar agent any a nivel global
El checkout se hizo primero en un stage propio
El agente basado en dockerfile se dejó solo para el stage de instalación y generación del PDF

De esta forma, cuando Jenkins entra en el contenedor, el repositorio ya está descargado en el workspace y el Dockerfile ya existe.
Esta versión avanzó bastante más, pero falló al instalar Marp con npm. Jenkins estaba ejecutando el contenedor con el UID/GID del usuario jenkins, no con el usuario node definido en el Dockerfile.
Por eso npm intentaba usar una caché en /.npm, y como ese directorio no tenía permisos correctos, la instalación fallaba.
La solución era obligar a npm a usar una caché dentro del workspace, donde sí tenía permisos de escritura.

---


## Versión final
``` groovy
pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    triggers {
        pollSCM('H/5 * * * *')
    }

    parameters {
        string(
            name: 'MD_FILE',
            defaultValue: 'slides/presentacion.md',
            description: 'Ruta del archivo markdown a procesar'
        )
    }

    stages {
        stage('Checkout desde SCM') {
            steps {
                checkout scm
                sh 'ls -la'
            }
        }

        stage('Instalación de dependencias y generación del PDF') {
            agent {
                dockerfile {
                    filename 'Dockerfile'
                    dir '.'
                    reuseNode true
                }
            }
            steps {
                sh '''
                    node --version
                    npm --version

                    if [ ! -f "${MD_FILE}" ]; then
                        echo "ERROR: no existe el archivo ${MD_FILE}"
                        exit 1
                    fi

                    export HOME="$WORKSPACE"
                    export npm_config_cache="$WORKSPACE/.npm"

                    mkdir -p "$npm_config_cache"

                    npm install --no-save @marp-team/marp-cli

                    mkdir -p pdf
                    nombre_pdf=$(basename "${MD_FILE}" .md)

                    npx @marp-team/marp-cli "${MD_FILE}" --pdf --allow-local-files -o "pdf/${nombre_pdf}.pdf"

                    ls -lh pdf
                '''
            }
        }

        stage('Archivado del artefacto') {
            steps {
                archiveArtifacts artifacts: 'pdf/*.pdf', fingerprint: true, onlyIfSuccessful: true
            }
        }
    }

    post {
        success {
            echo 'PDF generado y archivado correctamente.'
        }
        failure {
            echo 'La ejecución ha fallado.'
        }
        always {
            echo 'Fin del pipeline.'
        }
    }
}
```





