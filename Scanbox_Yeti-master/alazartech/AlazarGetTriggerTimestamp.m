function [retCode, boardHandle, pTimestampSamples] = AlazarGetTriggerTimestamp(boardHandle, record, pTimestampSamples)
[retCode, boardHandle, pTimestampSamples] = calllib('ATSApi', 'AlazarGetTriggerTimstamp', boardHandle, record, pTimestampSamples);
