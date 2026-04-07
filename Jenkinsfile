pipeline {
    agent {
        dockerfile {
            filename 'Dockerfile'
            dir '.' //Ruta del Dockerfile
            reuseNode true
        }
    }

    options {
        skipDefaultCheckout(true) // Evita el checkout automático al inicio del pipeline
        timestamps() // Muestra marcas de tiempo en la salida de la consola
        disableConcurrentBuilds() // Evita que se ejecuten múltiples builds concurrentes
        buildDiscarder(logRotator(numToKeepStr: '10')) // Mantiene solo los últimos 10 builds
    }

    triggers {
        pollSCM('H/5 * * * *') // Verifica cambios en el repositorio cada 5 minutos
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