<?php
/*
 * Fetches recent news posts from the forum
 */

// Returns the first post from topics in the specified forums
function get_recent_posts($forums, $limit = 5)
{
	global $auth, $db, $phpEx, $phpbb_content_visibility;
	
	$urls = [
		'topic'  => '/forum/viewtopic.' . $phpEx . '?f=%s&amp;t=%s',
	];
	
	// Build & execute the query
	$sql_array = [
        'SELECT' => 'p.post_time, p.post_text, p.bbcode_bitfield, p.bbcode_uid, t.topic_id, t.forum_id, t.topic_title, t.topic_posts_approved, t.topic_posts_unapproved, t.topic_posts_softdeleted',
        'FROM' => [
            POSTS_TABLE => 'p',
        ],
        'LEFT_JOIN' => [
            [
                'FROM' => [
					TOPICS_TABLE => 't'
				],
                'ON' => 't.topic_first_post_id = p.post_id',
            ],
        ],
        'WHERE' => $db->sql_in_set('t.forum_id', $forums) . '
			AND t.topic_status <> ' . ITEM_MOVED . '
			AND t.topic_visibility = ' . ITEM_APPROVED,
        'ORDER_BY' => 'p.post_id DESC',
    ];
    
    $sql = $db->sql_build_query('SELECT', $sql_array);

	$result = $db->sql_query_limit($sql, $limit);
	
	// Fill the posts array
	$posts = [];
	while ($row = $db->sql_fetchrow($result))
	{
		$posts[] = [
			'topic_title'   => censor_text($row['topic_title']),
			'topic_link'    => sprintf($urls['topic'], $row['forum_id'], $row['topic_id']),
			'topic_replies' => $phpbb_content_visibility->get_count('topic_posts', $row, $row['forum_id']) - 1,
			'post_time'     => \DateTime::createFromFormat('U', $row['post_time'])->format('Y-m-d H:i:s'),
			'post_text'     => generate_text_for_display($row['post_text'], $row['bbcode_uid'], $row['bbcode_bitfield'], ($row['bbcode_bitfield'] ? OPTION_FLAG_BBCODE : 0) | OPTION_FLAG_SMILIES, true),
		];
	}
	
	$db->sql_freeresult($result);
	
	return $posts;
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

$phpbb_content_visibility = $phpbb_container->get('content.visibility');

// The forum ids we want to retrieve topics from
$forums = [ 12 ];

echo json_encode(get_recent_posts($forums, $limit));
