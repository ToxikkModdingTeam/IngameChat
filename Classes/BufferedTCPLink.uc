/**
 * Code Taken from the ut2004 implementation of EpicGames.
 */
class BufferedTcpLink extends TcpLink;

var string			InputBuffer;
var string 			OutputBuffer;

var string			CRLF;
var string			CR;
var string			LF;

var bool			bWaiting;
var float			WaitTimeoutTime;
var string			WaitingFor;
var int				WaitForCountChars;	
var string			WaitResult;
var int				WaitMatchData;

function ResetBuffer()
{
    InputBuffer = "";
    OutputBuffer = "";
    bWaiting = false;
    CRLF = Chr(10) $ Chr(13);
    CR = Chr(13);
    LF = Chr(10);
}

function WaitFor(string What, float TimeOut, int MatchData)
{
    bWaiting = true;
    WaitingFor = What;
    WaitForCountChars = 0;
    WaitTimeoutTime = WorldInfo.TimeSeconds + TimeOut;
    WaitMatchData = MatchData;
    WaitResult = "";
}

function WaitForCount(int Count, float TimeOut, int MatchData)
{
    bWaiting = true;
    WaitingFor = "";
    WaitForCountChars = Count;
    WaitTimeoutTime = WorldInfo.TimeSeconds + TimeOut;
    WaitMatchData = MatchData;
    WaitResult = "";
}

function GotMatch(int MatchData)
{
}

function GotMatchTimeout(int MatchData)
{
}

function string ParseDelimited(string Text, string Delimiter, int Count, optional bool bToEndOfLine)
{
	local string Result;
	local int Found, i;
	local string s;

	Result = "";
	Found = 1;

	for(i=0;i<Len(Text);i++)
	{
		s = Mid(Text, i, 1);
		if(InStr(Delimiter, s) != -1)
		{
			if(Found == Count)
			{
				if(bToEndOfLine)
					return Result$Mid(Text, i);
				else
					return Result;
			}

			Found++;
		}
		else
		{
			if(Found >= Count)
				Result = Result $ s;
		}
	}

	return Result;
}
/**
 * Read an individual character, returns 0 if no characters waiting.
 */
function int ReadChar()
{
    local int C;

    if(InputBuffer == "")
    {
        return 0;
    }
    C = Asc(Left(InputBuffer, 1));
    InputBuffer = Mid(InputBuffer, 1);
    return C;

}

/**
 * Take a look at the next waiting character, return 0 if no characters waiting.
 */
function int PeekChar()
{
    if(InputBuffer == "")
    {
        return 0;
    }
    return Asc(Left(InputBuffer, 1));
}

/**
 * Read a line from the buffer.
 * @param string Text
 * @return bool
 */
function bool ReadBufferedLine(out string Text)
{
    local int I;

    I = InStr(InputBuffer, Chr(13));
    if(I == -1)
    {
        return false;
    }
    Text = Left(InputBuffer, I);
    if(Mid(InputBuffer, I + 1, 1) == Chr(10))
    {
        ++ I;
    }
    InputBuffer = Mid(InputBuffer, I + 1);
    return true;
}

function SendBufferedData(string Text)
{
    OutputBuffer $= Text;
}

event ReceivedText(string Text)
{
    InputBuffer $= Text;
}

/**
 * DoQueueIO is intended to be called from Tick();
 */
function DoBufferQueueIO()
{
	local int i;

	while(bWaiting)
	{
		if(WorldInfo.TimeSeconds > WaitTimeoutTime)
		{
			bWaiting = False;
			GotMatchTimeout(WaitMatchData);
		}

		if(WaitForCountChars > 0)
		{
			if(Len(InputBuffer) < WaitForCountChars)
				break;

			WaitResult = Left(InputBuffer, WaitForCountChars);
			InputBuffer = Mid(InputBuffer, WaitForCountChars);
			bWaiting = False;
			GotMatch(WaitMatchData);
		}
		else
		{
			i = InStr(InputBuffer, WaitingFor);
			if(i == -1 && WaitingFor == CR)
				i = InStr(InputBuffer, LF);
			if(i != -1)
			{
				WaitResult = Left(InputBuffer, i + Len(WaitingFor));
				InputBuffer = Mid(InputBuffer, i + Len(WaitingFor));
				bWaiting = False;
				GotMatch(WaitMatchData);
			}
			else
				break;
		}
	}

	if(IsConnected())
	{
		if( OutputBuffer != "" )
		{
			i = SendText(OutputBuffer);
			OutputBuffer = Mid(OutputBuffer, i);
		}
	}
}

defaultproperties
{
}