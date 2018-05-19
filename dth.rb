require 'yaml'

repo_url = ask("Introduce el url del repositorio (SSH), este sera agregado como origin remote del proyecto (opcional)")
run 'git init'
run 'git remote add template git@gitlab.com:devtohack/rails_template.git'
run 'git fetch template'
run 'git reset template/development'
run 'git reset --hard'

after_bundle do
  if !repo_url.blank?
    run "git remote add origin #{repo_url}"
  end
  run "git checkout -b development"
  run "rm app/assets/stylesheets/application.css"
  run "rm app/views/layouts/application.html.erb"
  run "rm app/views/layouts/mailer.html.erb"
  run "rm app/views/layouts/mailer.text.erb"
  run "yarn"

  if yes?("Desea configurar las variables de entorno de este proyecto? (Y/N)")
    variables = {
      "development" => {},
      "capistrano" => {}
    }

    with_db = yes?("Desea configurar la BD de este proyecto? (Y/N)")
    if with_db
      db_name = ask("Introduce el nombre de la BD mysql local:")
      db_user = ask("Introduce el usuario de mysql:")
      db_pass = ask("Introduce el password de mysql:")
      db_host = ask("Introduce el host de mysql (default localhost):")
      variables["development"] = {
        "DB_NAME" => db_name,
        "DB_USER" => db_user,
        "DB_PASS" => db_pass,
        "DB_HOST" => db_host ? db_host : 'localhost'
      }
      variables["test"] = {
        "DB_NAME" => db_name,
        "DB_USER" => db_user,
        "DB_PASS" => db_pass,
        "DB_HOST" => db_host ? db_host : 'localhost'
      }
    end

    if !repo_url.blank?
      with_deploy = yes?("Desea configurar el deploy de este proyecto? (Y/N)")
      if with_deploy
        dev_ip = ask("Introduce el dominio o IP del droplet para el enviroment DEVELOPMENT:")
        qa_ip = ask("Introduce el dominio o IP del droplet para el enviroment QA:")
        production_ip = ask("Introduce el dominio o IP del droplet para el enviroment PRODUCTION:")
        channel = ask("Introduce el nombre del channel de Slack (incluyendo el carcarter # si es un channel publico):")
        hook = ask("Introduce el hook de Slack para las notificaciones de deploy:")
        variables["capistrano"] = {
          "PROJECT_NAME" => 'rails_app',
          "REPO_URL" => repo_url,
          "DEV_DROPLET_IP" => dev_ip,
          "QA_DROPLET_IP" => qa_ip,
          "PRODUCTION_DROPLET_IP" => production_ip,
          "SLACK_CHANNEL" => channel,
          "SLACK_HOOK" => hook
        }
      end
    end

    File.open("config/environment_variables.yml", "w") do |file|
      file.write variables.to_yaml
    end

    if with_db
      run "rails db:create"
      run "rails db:migrate"
      run "rails db:seed"
    end

  end
end
