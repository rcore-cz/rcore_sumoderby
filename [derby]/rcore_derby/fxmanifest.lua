fx_version 'adamant'
games { 'gta5' }

client_scripts {
    "utils/cam.lua",
    "client/*.lua",
}

server_script {
    "utils/server.lua",
    "server/*.lua",
}

shared_scripts {
    "locales/*.lua",
    "config.lua",
}

dependencies {
    "ArenaAPI",
}

files {
    "html/*.*",
    "html/css/*.css",
    "html/scripts/*.js",
}

ui_page "html/index.html"