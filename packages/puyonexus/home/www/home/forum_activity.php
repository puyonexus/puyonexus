<?php
/*
 * Fetches recent forum posts
 */

// Returns topics that have had recent activity
function get_recent_topics($limit = 5)
{
	global $auth, $db, $user, $phpEx;
	
	$urls = [
		'topic'     => '/forum/viewtopic.' . $phpEx . '?f=%s&amp;t=%s',
		'last_post' => '/forum/viewtopic.' . $phpEx . '?f=%s&amp;t=%s&amp;p=%s#p%3$s',
		'profile'   => '/forum/memberlist.php?mode=viewprofile&amp;u=%s',
	];
	
	// Build & execute the query
	$sql_array = [
        'SELECT' => 't.topic_id, t.forum_id, t.topic_title, t.topic_last_post_id, t.topic_last_poster_id, t.topic_last_poster_name, t.topic_last_post_time, u.user_avatar_type, u.user_avatar',
        'FROM' => [
            TOPICS_TABLE => 't',
        ],
        'LEFT_JOIN' => [
			[
				'FROM' => [
					USERS_TABLE => 'u',
				],
				'ON' => 'u.user_id = t.topic_last_poster_id',
			],
        ],
        'WHERE' => $db->sql_in_set('t.forum_id', array_unique(array_keys($auth->acl_getf('f_read', true)))) . '
			AND t.topic_status <> ' . ITEM_MOVED . '
			AND t.topic_visibility = ' . ITEM_APPROVED,
        'ORDER_BY' => 't.topic_last_post_time DESC',
    ];
    
    $sql = $db->sql_build_query('SELECT', $sql_array);

	$result = $db->sql_query_limit($sql, $limit);
	
	// Fill the topics array
	$topics = [];
	while ($row = $db->sql_fetchrow($result))
	{
		$topics[] = [
			'topic_title'            => $row['topic_title'],
			'topic_last_poster_name' => $row['topic_last_poster_name'],
			'topic_last_post_time'   => \DateTime::createFromFormat('U', $row['topic_last_post_time'])->format('Y-m-d H:i:s'),
			'user_avatar'            => get_avatar($row),
			
			'topic_link'     => sprintf($urls['topic'], $row['forum_id'], $row['topic_id']),
			'last_post_link' => sprintf($urls['last_post'], $row['forum_id'], $row['topic_id'], $row['topic_last_post_id']),
			'user_link'      => sprintf($urls['profile'], $row['topic_last_poster_id']),
		];
	}
	
	$db->sql_freeresult($result);
	
	return $topics;
}

function get_avatar($user_row)
{
	global $phpbb_container;
	
	$row = \phpbb\avatar\manager::clean_row($user_row, 'user');

	$phpbb_avatar_manager = $phpbb_container->get('avatar.manager');
	$driver = $phpbb_avatar_manager->get_driver($row['avatar_type'], true);

	if ($driver)
	{
		return $driver->get_data($row, true)['src'];
	}

	return '';
}

// Check to see if $limit is valid
$limit = filter_var($_GET['limit'], FILTER_VALIDATE_INT);
if ($limit === false || $limit < 0 || $limit > 10)
{
	exit;
}

// File paths
define('PHPBB_ABS_PATH', '/home/puyonexus/apps/forum/phpbb/phpBB');
define('PHPBB_PATH',     '/forum');

// Initalize phpbb session
define('IN_PHPBB', true);
define('PHPBB_ROOT_PATH', PHPBB_ABS_PATH . '/');
define('PHPBB_USE_BOARD_URL_PATH', true);

$phpbb_root_path = (defined('PHPBB_ROOT_PATH')) ? PHPBB_ROOT_PATH : './';
$phpEx = substr(strrchr(__FILE__, '.'), 1);
include($phpbb_root_path . 'common.' . $phpEx);

// Start session management
$user->session_begin();
$auth->acl($user->data);
$user->setup();

echo json_encode(get_recent_topics($limit));
