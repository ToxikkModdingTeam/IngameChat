/*
 * Mutator adding the irc chat to the current game.
 * @copyright Thorsten 'stepotronic' Hallwas
 */
class IngameChatMutator extends UTMutator;

var IrcClient Client;
var IngameChat Chat;

function PostBeginPlay()
{
	super.PostBeginPlay();
    Client = Spawn(class'IrcClient');
    Chat = Spawn(class'LogIngameChat');
    Client.SetIngameChat(Chat);

    Client.Connect("port80a.se.quakenet.org", 6667, "UDKPlayer", "UDKtester", "UDKPlayer");

	SetTimer(10.0, false);
}

function Timer()
{
	Client.JoinChannel("#udk");
    Client.SendChannelMessage("#udk", "Sending you a message out of the udk :)");
	Client.SendChannelAction("#udk", "is very exited to be here");
	Client.LeaveChannel("#udk");
}

DefaultProperties
{
}