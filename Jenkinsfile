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