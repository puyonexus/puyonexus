<?php
return [
    'settings' => [
        // Site settings
        'site' => [
            'name' => 'Puyo Nexus Chain Simulator',
            'description' => 'Create and share Puyo Puyo chains.',
            'titledChainDescription' => 'Create and share Puyo Puyo chains with the Puyo Nexus Chain Simulator.',
            'twitter' => '@puyonexus',
        ],

        // View settings for PhpRenderer
        'views' => [
            'path' => __DIR__ . '/../views/',
        ],

        // Router cache
        'routerCacheFile' => __DIR__ . '/../temp/cache/routes.php',

        // Database settings
        'database' => [
            'dsn' => "mysql:host={$_ENV["MYSQL_HOSTNAME"]};dbname={$_ENV["MYSQL_DATABASE"]};charset=utf8",
            'username' => $_ENV["MYSQL_USERNAME"],
            'password' => $_ENV["MYSQL_PASSWORD"],
            'tablePrefix' => '',
        ],
    ]
];
