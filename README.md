# IngameChat
A little ingame chat framework in UDK for irc that i have been working on recently.

# Usage
Implement an IngameChat using the Interface. Idealy a graphical interface.
Instantiate the IrcClient and connect it to an irc server. 
Make the IrcClient aware of the Chat using SetIngameChat.

# Open Points
- Joining passworded channels
- Reacting to highlighting (can also be implemented by parsing the message in your IngameChat)
- Recognition of commands in messages that then would be delegated accordingly
