/**
 * Interface for IngameChat Clients.
 */
Interface IngameChat;

/**
 * Set the IrcClient to use for chatting.
 * @param IrcClient NewIrcClient
 */
function SetIrcClient(IrcClient NewIrcClient);

/**
 * This is just a notification that we can enable the rest of the options in the chat.
 * @param IpAddr ServerAddress
 */
function NotifyConnected(IpAddr ServerAddress);

/**
 * Notifies that the connection failed.
 * @param IpAddr ServerAddress
 * @param string Reason
 */
function NotifyConnectionFailed(IpAddr ServerAddress, string Reason);

/**
 * Notifies the server disconnected us. Disable chat features.
 */
function NotifyDisconnected();

/**
 * Sends a private message to another user. Delegate to IRCClient.
 * @param string Message
 * @param string Recipient
 */
function SendPrivateMessage(string Message, string Recipient);

/**
 * Notifies the message to the recipient failed.
 * @param string Recipient
 * @param string Reason
 */
function NotifyPrivateMessageFailed(string Recipient, string Reason);

/**
 * Send a Message to a channel. Delegate to IRCClient.
 * @param string Message
 * @param string Channel
 */
function SendChannelMessage(string Message, string Channel);

/**
 * Send an Action to a channel. Delegate to IRCClient.
 * @param string Action
 * @param string Channel
 */
function SendChannelAction(string Action, string Channel);

/**
 * Notifes the channel message failed.
 * @param string Channel
 * @param string Reason
 */
function NotifyChannelMessageFailed(string Channel, string Reason);

/**
 * Attempt to join a channel. Delegate to IRCClient.
 * @param string Channel
 * @param string Password optional
 */
function JoinChannel(string Channel, optional string Password);

/**
 * Attempt to leave a channel. Delegate to IRCClient.
 * @param string Channel
 */
function LeaveChannel(string Channel);

/**
 * Confirms the channel has been left.
 * @param string Channel
 */
function NotifyLeftChannel(string Channel);

/**
 * Confirms the channel has been joined.
 * @param string Channel
 */
function NotifyJoinedChannel(string Channel);

/**
 * Notifes joining the channel failed.
 * @param string Channel
 * @param string Reason
 */
function NotifyJoiningChannelFailed(string Channel, string Reason);
/**
 * Receive the channel topic.
 * @param string Channel
 * @param string Topic
 */
function ReceiveChannelTopic(string Channel, string Topic);

/**
 * Receive the channel users.
 * @param string Channel
 * @param array<string> Normal 
 * @param array<string> Voiced
 * @param array<string> HalfOps
 * @param array<string> Ops
 */
function ReceiveChannelUsers(string Channel, array<string> Normal, array<string> Voiced, array<string> HalfOps, array<string> Ops);

/**
 * Receive a message in a channel.
 * @param string Channel
 * @param string Message
 * @param string Author
 */
function ReceiveChannelMessage(string Channel, string Message, string Author);

/**
 * Receive a private message.
 * @param string Message
 * @param string Author
 */
function ReceivePrivateMessage(string Message, string Author);

/**
 * Receives an invitation to a channel promt the user.
 * @param string Channel
 */
function ReceiveInvite(string Channel);

/**
 * Attempts to change the nickname.
 * @param string NewNickName
 */
function ChangeNickame(string NewNickName);

/**
 * Nickname could not be changed.
 * @param string Reason
 */
function DeclineChangedNickname(string Reason);

/**
 * Receives a new Nickname update the chat.
 * @param string Nickname
 */
function NotifyChangedNickname(string Nickname);

/**
 * Notifies when a mode of a user has changed in a channel.
 * @param string Channel
 * @param string AffectedUser
 * @param string InitiatingUser
 * @param string Mode
 * @param string Modifier
 */
function NotifyChannelModeChangeOnUser(string Channel, string AffectedUser, string InitiatingUser, string Mode, string Modifier);

/**
 * Notifies when a user left the given channel.
 * @param string Channel
 * @param string User
 */
function NotifyUserLeftChannel(string Channel, string User);

/**
 * Notifies when a user entered the given channel.
 * @param string Channel
 * @param string User
 */
function NotifyUserEnteredChannel(string Channel, string User);

/**
 * Notifies when a user was kicked from a channel.
 * @param string Channel
 * @param string User
 * @param string Reason
 */
function NotifyUserKickedFromChannel(string Channel, string User, string Reason);
