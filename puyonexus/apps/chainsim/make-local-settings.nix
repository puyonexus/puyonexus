{
  baseUrl,
  basePath,
  databaseDsn,
  databaseUsername,
  databasePassword,
}:
let
  mkNowDoc = value: "<<<'ENDVAL'\n${value}\nENDVAL";
in
''
  <?php
  return [
    'settings' => [
      'site' => [
        'name' => 'Puyo Nexus Chain Simulator',
        'description' => 'Create and share Puyo Puyo chains.',
        'titledChainDescription' => 'Create and share Puyo Puyo chains with the Puyo Nexus Chain Simulator.',
        'twitter' => '@puyonexus',
        'baseUrl' => ${mkNowDoc baseUrl},
        'basePath' => ${mkNowDoc basePath},
        'cacheDir' => '/data/chainsim-cache',
      ],
      'database' => [
          'dsn' => ${mkNowDoc databaseDsn},
          'username' => ${mkNowDoc databaseUsername},
          'password' => ${mkNowDoc databasePassword},
      ],
    ]
  ];
''
