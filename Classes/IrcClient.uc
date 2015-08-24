/**
 * Rudimentary client for internet relay chat within udk.
 * 
 * Part of the Code is taken from the ut2004 source code.
 * 
 * Status codes taken from: https://www.alien.net.au/irc/irc2numerics.html
 * Most channel modes tested: https://www.quakenet.org/help/general/what-channel-modes-are-available-on-quakenet
 * @copyright Thorsten 'stepotronic' Hallwas
 */
class IrcClient extends BufferedTcpLink;

var IpAddr ServerAddress;
var string NickSuffix;
var string NickName;
var string UserIdent;
var string FullName;

/**
 * The chat interface that receives the events. 
 */
var IngameChat Chat;

var array<string> Channels;

/**
 * Disable tick for the connection process.
 */
function PostBeginPlay()
{
	Super.PostBeginPlay();
	Disable('Tick');
}

/**
 * Starts the connection process.
 * @param string ServerHost
 * @param int    ServerPort
 * @param string WantedNickname
 * @param string WantedIdent
 * @param string WantedFullName
 */
function Connect(string ServerHost, int ServerPort, string WantedNickName, string WantedIdent, string WantedFullName)
{
	ServerAddress.Port = ServerPort;
	NickName = WantedNickName;
	UserIdent = WantedIdent;
	FullName = WantedFullName;
	NickSuffix = "";
	if (BindPort() == 0)
	{
		if (Chat != None)
		{
			Chat.NotifyConnectionFailed(ServerAddress, "Could not bind a port");
			GotoState('NotConnected');
		}
	}
	Resolve(ServerHost);
	ResetBuffer();
}

/**
 * Set the Ingame chat which is the receiver and delegator of Messages.
 */
function SetIngameChat(IngameChat NewIngameChat)
{
	Chat = NewIngameChat;
	Chat.SetIrcClient(self);
	if (IsInState('Connected'))
	{
		GotoState('ConnectedWithChat');
	}
}

/**
 * When resolving the server failed.
 */
event ResolveFailed()
{
	if (Chat != None)
	{
		Chat.NotifyConnectionFailed(ServerAddress, "Could not resolve the given server");
	}
	GotoState('NotConnected');
}

/**
 * When the Address has been resolved, open the connection.
 */
event Resolved(IpAddr Address)
{
	ServerAddress.Addr = Address.Addr;
	Open(ServerAddress);
}

/**
 * After openening the connection go to the LoggingIn State. 
 */
event Opened()
{
    Enable('Tick');
    GotoState('LoggingIn');
}

/**
 * When the Connection is closed by the server, reconnect.
 */
event Closed()
{
	local string CurrentAddress;
	local array<string> CurrentAddressParts;
    Disable('Tick');
    GotoState('NotConnected');
	
	CurrentAddress = IpAddrToString(ServerAddress);
	ParseStringIntoArray(CurrentAddress, CurrentAddressParts, ":", true);
	Connect(CurrentAddressParts[0], int(CurrentAddressParts[1]), NickName, UserIdent, FullName);
	if (Chat != None)
	{
		Chat.NotifyDisconnected();
	}
}

/**
 * Every tick check if there is anything that needs to be processed.
 */
function Tick(float DeltaTime)
{
	local string Line;

	DoBufferQueueIO();
	if(ReadBufferedLine(Line))
	{
		ProcessInput(Line);
	}

    Super.Tick(DeltaTime);
}

function SendChannelMessage(string Channel, string Message)
{
	`Log("Send channel message ignored, not connected yet.");
}

function SendPrivateMessage(string Recipient, string Message)
{
	`Log("Send private message ignored, not connected yet.");
}

function SendChannelAction(string Channel, string Text)
{
	`Log("Send channel action ignored, not connected yet.");
}

/**
 * Sends the Action into the given Recipient.
 * @param string Recipient
 * @param string Action
 */
function SendPrivateAction(string Recipient, string Action)
{
	`Log("Send private action ignored, not connected yet.");
}

function JoinChannel(string Channel, optional string Password)
{
	`Log("Joining channel ignored, not connected yet");
}	

function LeaveChannel(string Channel, optional string Message)
{
	`Log("Leaving channel ignored, not connected yet");
}

function Disconnect(string Reason)
{
	`Log("Quitting ignored, not connected yet");
}

/**
 * Change the mode on the channel. Example +k password
 * @param string Channel
 * @param string Mode
 * @param string Modifier
 * @param string Parameter
 */
function ChangeChannelMode(string Channel, string Modifier, string Mode, optional string Parameter)
{
	`Log("Changing Channel mode ignored, not connected yet.");
}

/**
 * Our initial state, we are not connected yet.
 */
auto state NotConnected
{
	
}

/**
 * State when we log in to the server.
 */
state LoggingIn
{
	function Timer()
	{
		SendSetNickName();
	}

	/**
	 * Start with sending user
	 * @param Name PreviousStateName
	 */
	function BeginState(Name PreviousStateName)
	{
		LogIn();
		SendSetNickName();
		SetTimer(1.0, false);
	}

	/**
	 * React to the server response.
	 * @param string Line
	 */
	function ProcessInput(string Line)
	{
		local array<string> SplitResponse;
		local string StatusBit;

		`Log("LoggingIn-Response: " $ Line);

		 ParseStringIntoArray(Line, SplitResponse, " ", true);
		 if (SplitResponse.Length > 2)
		 {
		 	StatusBit = SplitResponse[1];
	 		ProcessResponse(StatusBit);
		 } 
		 else 
		 {
		 	global.ProcessInput(Line);
		 }
	}

	/**
	 * Processes the Status code and restarts a LogIn if not successful.
	 * @param string StatusBit
	 */
	function ProcessResponse(string StatusBit)
	{
		`Log("Processing Status bit: " $ StatusBit);
		switch (StatusBit)
		{
			case "432": // nickname invalid
				// @todo ideally we already made sure the nickname works up to this point, but i believe we can also promt for a new one
				FilterNick();
				LogIn();
				break;

			case "433": // nickname taken
			case "436": // nickname conflict
				IncrementNickSuffix();
				SetTimer(1.0, false);
				break;
			case "AUTH": // Server requesting auth, delaying
				// @todo listen to port 113 and reply
				break;	
			case "Error":
				if (Chat != None)
				{
					Chat.NotifyConnectionFailed(ServerAddress, "Failed to connect due to errors");
				}
				GotoState('NotConnected');
				break;
			default:
				GotoState('Connected');
		}
	}
}

/**
 * State when we are connected without a chat.
 */
state Connected
{
	function BeginState(Name PreviousStateName)
	{
		if (Chat != None)
		{
			GotoState('ConnectedWithChat');
		}
	}
}

/**
 * State when we are connected with a chat that can interact with this.
 */
state ConnectedWithChat
{
	/**
	 * Sends the Message to the given recipient.
	 * @param string Recipient
	 * @param string Message
	 */
	function SendPrivateMessage(string Recipient, string Message)
	{
		if (!IsMessageCommandThenDelegate(Message))
		{
			SendBufferedData("PRIVMSG " $ Recipient $ " :" $ Message $ CRLF);	
		}
	}

	/**
	 * Sends the Message into the given Channel.
	 * @param string Channel
	 * @param string Message
	 */
	function SendChannelMessage(string Channel, string Message)
	{
		if (!IsMessageCommandThenDelegate(Message, Channel))
		{	
			// let's join it before be message to it
			if (Channels.Find(Channel) == -1)
			{
				JoinChannel(Channel);
			}
			SendBufferedData("PRIVMSG " $ Channel $ " :" $ Message $ CRLF);
		}
	}

	/**
	 * Sends the Notice Message to specified Target.
	 * @param string Target
	 * @param string Message
	 */
	function SendNotice(string Target, string Message)
	{
		SendBufferedData("NOTICE " $ Target $ " :" $ Message $ CRLF);
	}

	/**
	 * Returns true if the message is a command.
	 */
	function bool IsMessageCommandThenDelegate(string Message, optional string Channel, optional string Recipient)
	{
		local string PossibleCommand;
		local array<string> SplitRequest;
		local bool bCommandFound;

		bCommandFound = false;
		if (Left(Message, 1) == "/") 
		{
			// remove slash and split
			Message = Mid(Message, 1);
			ParseStringIntoArray(Message, SplitRequest, " ", true);		
			PossibleCommand = Locs(SplitRequest[0]);

			switch(PossibleCommand) 
		 	{
		 		case "join": // we seem to wanna join a channel: join #channel password
		 			if (SplitRequest.Length > 1 && len(SplitRequest[1]) > 0) 
		 			{
		 				if (SplitRequest.Length > 2 && len(SplitRequest[2]) > 0) // we seem to have a password added
		 				{
		 					JoinChannel(SplitRequest[1], SplitRequest[2]);
		 				}
		 				else
		 				{
		 					JoinChannel(SplitRequest[1]);
		 				}
		 				bCommandFound = true;
		 			}
		 			break;
	 			case "part": 
	 				if (SplitRequest.Length == 1 && len(Channel) > 0) // we leave the channel we are in
	 				{
	 					LeaveChannel(Channel);
	 					bCommandFound = true;
	 				}
	 				else if (SplitRequest.Length > 1 && len(SplitRequest[1]) > 0)
	 				{
		 				if (SplitRequest.Length > 2 && len(SplitRequest[2]) > 0) // we seem try to leave a message
		 				{
		 					LeaveChannel(SplitRequest[1], ConcatFromIndexTillRestOfArray(SplitRequest, 2));
		 				}
		 				else
		 				{
		 					LeaveChannel(SplitRequest[1]);
		 				}
		 				bCommandFound = true;
	 				}
	 				break;
	 			case "msg":
	 			case "privmsg": // we need a channel or a user and a message
	 				if (SplitRequest.Length > 2)
	 				{
	 					if (Left(SplitRequest[1], 1) == "#")
	 					{
	 						// make sure we are already in that channel since most networks don't allow external messages
	 						if (Channels.Find(SplitRequest[1]) == -1)
	 						{
	 							JoinChannel(SplitRequest[1]);
	 						}
	 						SendChannelMessage(SplitRequest[1], ConcatFromIndexTillRestOfArray(SplitRequest, 2));
	 					}
	 					else 
	 					{
	 						SendPrivateMessage(SplitRequest[1], ConcatFromIndexTillRestOfArray(SplitRequest, 2));
	 					}
	 					bCommandFound = true;
	 				}
	 				break;
	 			case "amsg": // send to all channels we are in
	 				break;	
	 			case "me":
	 				if (len(Channel) > 0) 
	 				{
	 					SendChannelAction(Channel, ConcatFromIndexTillRestOfArray(SplitRequest, 1));
	 					bCommandFound = true;
	 				}
	 				else if (len(Recipient) > 0)
	 				{
	 					SendPrivateAction(Recipient, ConcatFromIndexTillRestOfArray(SplitRequest, 1));
	 					bCommandFound = true;
	 				}	
	 				break;
	 			case "nick":
					ChangeNick(SplitRequest[1]);
					break;
				case "notice":
					if ( SplitRequest.Length > 2 )
					{
						SendNotice(SplitRequest[1], ConcatFromIndexTillRestOfArray(SplitRequest, 2));
						bCommandFound = true;
					}
					break;
		 	}
		}

		return bCommandFound;
	}

	/**
	 * Sends the Action into the given Channel.
	 * @param string Channel
	 * @param string Action
	 */
	function SendChannelAction(string Channel, string Action)
	{
		SendChannelMessage(Channel, Chr(1) $ "ACTION" @ Action $ Chr(1));
	}

	/**
	 * Sends the Action into the given Recipient.
	 * @param string Recipient
	 * @param string Action
	 */
	function SendPrivateAction(string Recipient, string Action)
	{
		SendPrivateMessage(Recipient, Chr(1) $ "ACTION" @ Action $ Chr(1));
	}

	/**
	 * Join the channel.
	 * @param string Channel
	 */
	function JoinChannel(string Channel, optional string Password)
	{
		local string JoinString;

		PrependHash(Channel);

		JoinString = "JOIN " $ Channel;
		if (len(Password) > 0)
		{
			JoinString @= Password;
		}

		SendBufferedData(JoinString $ CRLF);
	}

	/**
	 * Leave the channel.
	 * @param string Channel
	 * @param string Message optional
	 */
	function LeaveChannel(string Channel, optional string Message)
	{
		local string LeaveString;
		PrependHash(Channel);

		LeaveString = "PART " $ Channel;
		if (len(Message) > 0)
		{
			LeaveString @= Message;
		}

		SendBufferedData(LeaveString $ CRLF);
	}

	/**
	 * Disconnect from the server.
	 */
	function Disconnect(string Reason)
	{
		SendText("QUIT :" $ Reason $ CRLF);
	}

	/**
	 * Changes nick
	 * @param string NewNick
	 */
	function ChangeNick(string NewNick)
	{
		SendBufferedData("NICK " $ NewNick $ CRLF);
	}

	/**
	 * Start with sending user
	 */
	function BeginState(Name PreviousStateName)
	{
		`Log("I am connected and i have got a chat.");
		Chat.NotifyConnected(ServerAddress);
	}

	/**
	 * Split incoming and delegate accordingly.
	 */
	function ProcessInput(string Line)
	{
		local array<string> SplitResponse;
		local string StatusBit;

		ParseStringIntoArray(Line, SplitResponse, " ", true);
		if (SplitResponse.Length > 2)
		{
			StatusBit = SplitResponse[1]; // @todo why can i not switch directly on the part of the array?
			switch(StatusBit) 
		 	{
		 		case "PRIVMSG": // we received a message, let's find out if it is private or for a channel
		 			DelegateMessage(SplitResponse);
		 			break;
		 		case "332": // either when we joined the channel or we get noticed after someone changed it.
		 		case "TOPIC":
		 			DelegateChannelTopic(SplitResponse);
		 			break;
		 		case "JOIN": // confirmation we joined a channel
		 			Chat.NotifyJoinedChannel(SplitResponse[2]);
					Channels.AddItem(SplitResponse[2]);
		 			break;
		 		case "PART": // confirmation we left a channel
		 			Chat.NotifyLeftChannel(SplitResponse[2]);
					Channels.RemoveItem(SplitResponse[2]);
					break;
		 		case "470": // we were kicked
		 		case "KICK":
		 			Chat.NotifyUserKickedFromChannel(SplitResponse[2], SplitResponse[3], SplitResponse[4]); // 4 contains the reason
		 			break;
		 		case "INVITE":
		 			Chat.ReceiveInvite(SplitResponse[3]); // 2 contains our own name
		 			break;
				case "MODE":
					DelegateModeChangeOnChannel(SplitResponse);	
					break;
		 		case "353": // list of users
		 			DelegateUserList(SplitResponse);
		 			break;
		 		case "401": // sending failed, user not found
					Chat.NotifyPrivateMessageFailed(SplitResponse[3], Mid(SplitResponse[4], 1) $ ConcatFromIndexTillRestOfArray(SplitResponse, 4, true));
					break;
				case "403": // sending to channel failed, channel not found
					Chat.NotifyChannelMessageFailed(SplitResponse[3], Mid(SplitResponse[4], 1) $ ConcatFromIndexTillRestOfArray(SplitResponse, 4, true)); 
					break;
				case "404": // sending to channel failed, forbidden
					Chat.NotifyChannelMessageFailed(SplitResponse[3], Mid(SplitResponse[4], 1) $ ConcatFromIndexTillRestOfArray(SplitResponse, 4, true));
					break;
				case "405": // we already joined too many channels
				case "471": // channel is at limit
				case "473": // channel is invite only
				case "474": // we are banned
				case "475": // we don't have the password
				case "477": // we need to register
					Chat.NotifyJoiningChannelFailed(SplitResponse[3], Mid(SplitResponse[4], 1) $ ConcatFromIndexTillRestOfArray(SplitResponse, 4, true));
					break;
				case "NOTICE":  // we received a notice (private channel messages sent by Q bot)
					Chat.ReceiveNotice(ConcatFromIndexTillRestOfArray(SplitResponse, 3, true), ExtractAuthorNickName(SplitResponse[0]));
					break;
		 	}
		} 
		else 
		{
			global.ProcessInput(Line);
		}
	}

	/**
	 * Delegate mode changes. This is very limited, since in the end we need to rely on the server.
	 * @param array<string> SplitResponse
	 */
	function DelegateModeChangeOnChannel(array<string> SplitResponse)
	{
		local string Channel, InitiatingUser, Mode, Modifier;
		local int i;

		InitiatingUser = ExtractAuthorNickName(SplitResponse[0]);
		Channel = SplitResponse[2];
		Modifier = Left(SplitResponse[3], 1);
		Mode = Mid(SplitResponse[3], 1, 1);

		if (InStr("bhov", Mode) != -1) // ban, halfop, operator, voice
		{
			for (i = 4; i < SplitResponse.Length; i++)
			{
				Chat.NotifyChannelModeChangeOnUser(Channel, SplitResponse[i], InitiatingUser, Modifier, Mode);
			}
		}
		else 
		{
			if (SplitResponse.Length > 4 && len(SplitResponse[4]) > 0 )
			{
				Chat.NotifyChannelModeChange(Channel, InitiatingUser, Modifier, Mode, SplitResponse[4]);	
			}
			else 
			{
				Chat.NotifyChannelModeChange(Channel, InitiatingUser, Modifier, Mode);
			}
			
		}
	}

	/**
	 * Identify the status of the users and then hand them over to the chat.
	 * @param array<string> SplitResponse
	 */
	function DelegateUserList(array<string> SplitResponse)
	{
		local int i;
		local array<string> Normal;
		local array<string> Voiced;
		local array<string> HalfOps;
		local array<string> Ops;
		local string CurrentUser;

		// remove the colon
		CurrentUser = Mid(SplitResponse[5], 1);
		// there is always one user us :)
		SortUserIntoGroup(CurrentUser, Normal, Voiced, HalfOps, Ops);

		if (SplitResponse.length > 6)
		{
			for (i = 6; i < SplitResponse.Length; i++)
			{
				CurrentUser = SplitResponse[i];
				SortUserIntoGroup(CurrentUser, Normal, Voiced, HalfOps, Ops);
			}
		}

		Chat.ReceiveChannelUsers(SplitResponse[4], Normal, Voiced, HalfOps, Ops);
	}

	/**
	 * Put the user into the correct array.
	 * @param string User
	 * @param array<string> Normal 
	 * @param array<string> Voiced 
	 * @param array<string> HalfOps
	 * @param array<string> Ops
	 */
	function SortUserIntoGroup(string User, out array<string> Normal, out array<string> Voiced, out array<string> HalfOps, out array<string> Ops)
	{
		local string Status;

		Status = Left(User, 1);
		switch (Status)
		{
			case "@":
				Ops.AddItem(Mid(User, 1));
				break;
			case "%":	
				HalfOps.AddItem(Mid(User, 1));
				break;
			case "+":
				Voiced.AddItem(Mid(User, 1));
				break;
			default:
				Normal.AddItem(User);
		}
	}

	/**
	 * Extracts the authors nickname.
	 * @param string FullAuthor
	 * @return string
	 */ 
	function string ExtractAuthorNickName(string FullAuthor)
	{
		local string Author;
		local array<string> SplitAuthor; 

		// the author is in the format: Nickname!ident@host and there is a colon in front of it.
		ParseStringIntoArray(FullAuthor, SplitAuthor, "!", true);
		Author = Mid(SplitAuthor[0], 1);

		return Author;
	}

	/**
	 * Delegates the message to the ingame chat.
	 * @param array<string> SplitResponse
	 * @todo recognize ACTION (/me)
	 */
	function DelegateMessage(array<string> SplitResponse)
	{
		local string Message;
		local string Author;
		local string Channel;

		Author = ExtractAuthorNickName(SplitResponse[0]);
		Message = ConcatFromIndexTillRestOfArray(SplitResponse, 3, true);
		if (SplitResponse[2] == NickName) // it is private
		{
			Chat.ReceivePrivateMessage(Message, Author);
		} 
		else 
		{
			Channel = SplitResponse[2];
			Chat.ReceiveChannelMessage(Channel, Message, Author);
		}
	}

	/**
	 * Delegates the topic information to the ingame chat.
	 * @param array<string> SplitResponse
	 */
	function DelegateChannelTopic(array<string> SplitResponse)
	{
		local string Channel;
		local string Topic;

		Channel = SplitResponse[2];
		Topic = ConcatFromIndexTillRestOfArray(SplitResponse, 3, true);
		Chat.ReceiveChannelTopic(Channel, Topic);
	}

	/**
	 * Change the user mode on the channel.
	 * @param string Channel
	 * @param string User
	 * @param string Mode
	 * @param string Modifier
	 */
	function ChangeUserModeOnChannel(string Channel, string User, string Modifier, string Mode)
	{
		ChangeChannelMode(Channel, Modifier, Mode, User);
	}

	/**
	 * Change the mode on the channel. Example +k password
	 * @param string Channel
	 * @param string Mode
	 * @param string Modifier
	 * @param string Parameter
	 */
	function ChangeChannelMode(string Channel, string Modifier, string Mode, optional string Parameter)
	{
		local string ModeString;

		ModeString = "MODE" @ Channel @ Modifier $ Mode;
		if (len(Parameter) > 0)
		{
			ModeString @= Parameter;
		}
		SendBufferedData(ModeString);
	}
}

/**
 * Concatenates the array from the given index till the end of the array.
 * @param array<string> StringArray
 * @param int Index
 * @param optional bool bTrimColon=false
 * @return string
 */
static function string ConcatFromIndexTillRestOfArray(out array<string> StringArray, int Index, optional bool bTrimColon=false)
{
	local string ConcatString;
	local int i;

	if ( Index < StringArray.Length )
	{
		if ( bTrimColon )
			ConcatString = Mid(StringArray[Index], 1);
		else
			ConcatString = StringArray[Index];

		for ( i=Index+1; i<StringArray.Length; i++ )
		{
			ConcatString @= StringArray[i];
		}
	}

	return ConcatString;
}

/**
 * Make sure the Hash is the first character for the channel.
 * @param string Channel
 */
function PrependHash(out string Channel)
{
	if(Left(Channel, 1) != "#")
	{
		Channel = "#" $ Channel;
	}
}

/**
 * Globally valid reponses.
 * @param string Line
 */
function ProcessInput(string Line)
{
	local string PongLine;

	if(Left(Line, 5) == "PING ") // Standard is just to let the server know we are still online.
	{
		PongLine = "PONG " $ Mid(Line, 5) $ CRLF;
		`Log(PongLine);
		SendBufferedData(PongLine);
	}
	else if(Left(Line, 5) == "NICK ")
	{
		`Log("Received nick confirmation");
		if (Chat != None)
		{
			Chat.NotifyChangedNickname(NickName);
		}	
	}
}

/**
 * Sends the login request.
 */
function LogIn()
{
	local string LoginLine;

	LoginLine = "USER " $ UserIdent $ " localhost " $ IpAddrToString(ServerAddress) $ " :" $ FullName $ CRLF;
	SendBufferedData(LoginLine);
}

/**
 * Set the nickname on the server.
 */
function SendSetNickName()
{
	SendBufferedData("NICK " $ NickName $ NickSuffix $ CRLF);
}

/**
 * Set the nickname of this chat.
 * @param string WantedNickName
 */
function SetNickName(string WantedNickName)
{
	NickName = WantedNickName;
	FilterNick();
}

/**
 * Returns the current nickname.
 */
function string GetNickName()
{
	return NickName;
}

/**
 * Increment the number behind the nick.
 */
function IncrementNickSuffix()
{
	local int CurrentNickSuffix;		

	CurrentNickSuffix = int(NickSuffix);
	++CurrentNickSuffix;
	NickSuffix = string(CurrentNickSuffix);		
}	

/**
 * Remove all characters not supported.
 */
function FilterNick()
{
	local string NewNick;
	local string Character;
	local int i;
	// no reg-ex in unreal-script? <o>

	Character =  Left(NickName, 1);
	if (IsCharacterLetter(Character))
	{
		NewNick = Character;
	}
	else
	{
		NewNick = "T";
	}

	for (i=1; i < Len(NickName); i++)
	{
		Character = Mid(NickName, i, 1);
		if (IsCharacterValid(Character)) 
		{
			`Log("Valid Character " $ Character);
			NewNick = NewNick $ Character;
		}
		else
		{
			`Log("Invalid Character " $ Character);
			NewNick = NewNick $ "_";
		}
	}
	NickName = NewNick;
}

/**
 * Returns true if the given character is allowed.
 * @param string Character
 * @return bool
 */
function bool IsCharacterValid(string Character)
{
	local bool IsValid;

	IsValid = false;
	if (len(Character) == 1)
	{
		return IsCharacterLetter(Character) || IsCharacterNumber(Character) || IsCharacterAllowedSpecial(Character);
	}

	return IsValid;
}

/**
 * Returns true if the given character is an allowed special character.
 * @param string Character
 * @return bool
 */
function bool IsCharacterAllowedSpecial(string Character)
{
	return InStr("_-|[]{}^`\\", Character) >= 0;
}

/**
 * Returns true if the given character is a number.
 * @param string Character
 * @return bool
 */
function bool IsCharacterNumber(string Character)
{
	return InStr("0123456789", Character) >= 0;
}

/**
 * Returns true if the given character is a letter.
 * @param string Character
 * @return bool
 */
function bool IsCharacterLetter(string Character)
{
	return InStr("abcdefghijklmanopqrstuvwxyz", Locs(Character)) >= 0;
}

DefaultProperties
{
}
