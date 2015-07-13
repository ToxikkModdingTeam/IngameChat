class LogIngameChat extends Actor implements (IngameChat);

var IrcClient Client;

/**
 * Set the IrcClient to use for chatting.
 */
function SetIrcClient(IrcClient NewIrcClient)
{
	`Log("IngameChat: We just set the irc client");
	Client = NewIrcClient;
}

/**
 * This is just a notification that we can enable the rest of the options in the chat.
 */
function NotifyConnected(IpAddr ServerAddress)
{
	`Log("IngameChat: We are connected to" @ ServerAddress.Addr $ ":" $ ServerAddress.Port);
}

/**
 * Notifies that the connection failed.
 * @param IpAddr ServerAddress
 * @param string Reason
 */
function NotifyConnectionFailed(IpAddr ServerAddress, string Reason)
{
	`Log("IngameChat: Connection failed to" @ ServerAddress.Addr $ ":" $ ServerAddress.Port @ "-" @ Reason);
}

/**
 * Notifies the server disconnected us.
 */
function NotifyDisconnected()
{
	`Log("IngameChat: Disconnected");
}

/**
 * Sends a private message to another user.
 */
function SendPrivateMessage(string Message, string Recipient)
{
	`Log("IngameChat: Sending" @ Message @ "to" @ Recipient);
}

/**
 * Send a Message to a channel.
 */
function SendChannelMessage(string Message, string Channel)
{
	`Log("IngameChat: Sending" @ Message @ "to channel" @ Channel);
}

/**
 * Send an Action to a channel.
 */
function SendChannelAction(string Action, string Channel)
{
	`Log("IngameChat: Sending Action " @ Action @ "to channel" @ Channel);
}

/**
 * Attempt to join a channel.
 */
function JoinChannel(string Channel, optional string Password)
{
	`Log("IngameChat: Joining" @ Channel @ Password);
}

/**
 * Attempt to leave a channel.
 */
function LeaveChannel(string Channel)
{
	`Log("IngameChat: Leaving" @ Channel);
}

/**
 * Confirms the channel has been left.
 */
function NotifyLeftChannel(string Channel)
{
	`Log("IngameChat: Left" @ Channel);
}

/**
 * Confirms the channel has been joined.
 */
function NotifyJoinedChannel(string Channel)
{
	`Log("IngameChat: Joined" @ Channel);
}

/**
 * Receive the channel topic.
 */
function ReceiveChannelTopic(string Channel, string Topic)
{
	`Log("IngameChat: Topic for" @ Channel @ "is '" $ Topic $ "'");
}

/**
 * Receive the channel users.
 */
function ReceiveChannelUsers(string Channel, array<string> Normal, array<string> Voiced, array<string> HalfOps, array<string> Ops)
{
	local string NormalUsers;
	local string VoicedUsers;
	local string HalfOpUsers;
	local string OpUsers;

	JoinArray(Normal, NormalUsers);
	`Log("IngameChat: Normal Users:" @  NormalUsers);
	JoinArray(Voiced, VoicedUsers);
	`Log("IngameChat: Voiced Users:" @  VoicedUsers);
	JoinArray(HalfOps, HalfOpUsers);
	`Log("IngameChat: HalfOp Users:" @  HalfOpUsers);
	JoinArray(Ops, OpUsers);
	`Log("IngameChat: Op Users:" @  OpUsers);	
}

/**
 * Receive a message in a channel.
 */
function ReceiveChannelMessage(string Channel, string Message, string Author)
{
	if (InStr(Message, Client.GetNickName())>= 0)
	{
		Client.SendChannelMessage(Channel, Author @ "is talking about me");	
	}
	
	`Log("IngameChat: Received" @ Message @ "in channel" @ Channel @ "from" @ Author);
}

/**
 * Receive a private message.
 */
function ReceivePrivateMessage(string Message, string Author)
{
	if (InStr(Message, "Hello")>= 0)
	{
		Client.SendPrivateMessage(Author, Message);	
	}	
	`Log("IngameChat: Received" @ Message @ "from" @ Author);
}

/**
 * Receives an invitation to a channel promt the user.
 */
function ReceiveInvite(string Channel)
{
	`Log("IngameChat: Received invite to" @ Channel);
}

/**
 * Attempts to change the nickname.
 */
function ChangeNickame(string NewNickName)
{
	`Log("IngameChat: Changing nickname to" @ NewNickName);
}

/**
 * Nickname could not be changed.
 */
function DeclineChangedNickname(string Reason)
{
	`Log("IngameChat: Changing nickname failed:" @ Reason);
}

/**
 * Receives a new Nickname update the chat.
 */
function NotifyChangedNickname(string Nickname)
{
	`Log("IngameChat: Changing nickname successful:" @ NickName);
}

/**
 * Notifies when a mode of a user has changed in a channel.
 * @todo split into multiple functions?
 */
function NotifyChannelModeChangeOnUser(string Channel, string AffectedUser, string InitiatingUser, string Mode, string Modifier)
{
	`Log("IngameChat:" @ InitiatingUser @ "changing mode on user" @ AffectedUser @ "in channel" @ Channel @ "to" @ Modifier $ Mode);
}

/**
 * Notifies when a user left the given channel.
 */
function NotifyUserLeftChannel(string Channel, string User)
{
	`Log("IngameChat: User" @ User @ "left channel" @channel);
}

/**
 * Notifies when a user entered the given channel.
 */
function NotifyUserEnteredChannel(string Channel, string User)
{
	`Log("IngameChat: User" @ User @ "entered channel" @channel);
}

/**
 * Notifies when a user was kicked from a channel.
 */
function NotifyUserKickedFromChannel(string Channel, string User, string Reason)
{
	`Log("IngameChat: User" @ User @ "kicked from channel" @ channel @ ":" @ Reason);
}

/**
 * Notifes the channel message failed.
 */
function NotifyChannelMessageFailed(string Channel, string Reason)
{
	`Log("IngameChat: Message in" @ Channel @ "failed:" @ Reason);
}

/**
 * Notifies the message to the recipient failed.
 */
function NotifyPrivateMessageFailed(string Recipient, string Reason)
{
	`Log("IngameChat: Message to" @ Recipient @ "failed:" @ Reason);
}

/**
 * Notifes joining the channel failed.
 * @param string Channel
 * @param string Reason
 */
function NotifyJoiningChannelFailed(string Channel, string Reason)
{
	`Log("IngameChat: Joining" @ Channel @ "failed:" @ Reason);
}

defaultproperties
{
	
}