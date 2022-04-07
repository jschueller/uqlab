function duration = uq_Dispatcher_util_computeDuration(datetime1,datetime2)
%UQ_DISPATCHER_UTIL_COMPUTEDURATION computes the duration between two dates
%   and return the duration as a char.
%
%   Inputs
%   ------
%   - datetime1: char, the first date and time
%       The format is 'dd/mm/yy HH:MM:SS PM'.
%   - datetime2: char, the second date and time
%       The format is 'dd/mm/yy HH:MM:SS PM'.
%       If datetime2 is earlier than datetime1, the duration is set to 0.
%
%   Output
%   ------
%   - duration: char, the duration in formatted char
%       The format is 'dd days hh hours mm mins ss secs' if dd > 0,
%       otherwise 'hh hours mm mins and ss secs'. Note that dd is not
%       limited to two characters, but however many characters the number 
%       required.
%
%   Example
%   -------
%       datetime1 = '06/03/20 10:29:29 AM';
%       datetime2 = '06/03/20 10:57:19 AM';
%       uq_Dispatcher_util_computeDuration(datetime1,datetime2)
%       % 00 hrs 27 mins 20 secs
%
%       datetime1 = '13/01/20 10:24:50 AM';
%       datetime2 = '06/02/21 11:29:59 PM';
%       uq_Dispatcher_util_computeDuration(datetime1,datetime2)
%       % 390 days 13 hrs 05 mins 09 secs

%% Convert to a date vector ([Y,MO,D,H,MI,S])
dateFormat = 'dd/mm/yy HH:MM:SS PM';
datetimeVec1 = datevec(datetime1,dateFormat);
datetimeVec2 = datevec(datetime2,dateFormat);

%% Compute the difference (in seconds)
diffDate = etime(datetimeVec2,datetimeVec1);

if diffDate < 0
    % Make sure there won't be a negative duration
    diffDate = 0;
end

%% Compute days, hours, minutes, and seconds
day2hours = 24;
hour2minutes = 60;
minute2seconds = 60;

durationDays = floor(diffDate/day2hours/hour2minutes/minute2seconds);
diffDate = diffDate - durationDays*day2hours*hour2minutes*minute2seconds;

durationHours = floor(diffDate/hour2minutes/minute2seconds);
diffDate = diffDate - durationHours*hour2minutes*minute2seconds;

durationMinutes = floor(diffDate/minute2seconds);
diffDate = diffDate - durationMinutes*minute2seconds;

durationSeconds = mod(diffDate,minute2seconds);

duration = '';
if durationDays > 0
    duration = sprintf('%s days ',num2str(durationDays));
end

duration = sprintf('%s%02d hrs %02d mins %02d secs',...
    duration, durationHours, durationMinutes, durationSeconds);

end
