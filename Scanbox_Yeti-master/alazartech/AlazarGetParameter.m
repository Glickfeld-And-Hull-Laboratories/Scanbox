function [retCode, boardHandle, pValue] = AlazarGetParameter(boardHandle, channel, parameter, pValue)
[retCode, boardHandle, pValue] = calllib('ATSApi', 'AlazarGetParameterUL', boardHandle, channel, parameter, pValue);
