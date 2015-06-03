
function args_out = icy_command(class_name, command, args_in)%#ok
% args_out = icy_command(class_name, command, args_in)
% 
% Low-level function to execute a command in Icy from Matlab.
%
% This function should not be used directly by final-users.

% Sessions identifiers
mlock;
persistent client_ID;
persistent path_in  ;
persistent path_out ;

% Loop for session ID renewing
remaining_attemps = 2;
while(true)

	% Get a session ID if necessary
	if(~exist('client_ID', 'var') || isempty(client_ID))
		msg_in    = cell(1, 1);
		msg_in{1} = '?';
		msg_out   = send_command(msg_in);
		if(length(msg_out)~=4 || ~strcmp(msg_out{1}, 'ID'))
			error('Unconsistent answer (expected: ID)');
		end
		client_ID = msg_out{2};
		path_in   = msg_out{3};
		path_out  = msg_out{4};
	end
	remaining_attemps = remaining_attemps - 1;

	% Write the in file
	if(~exist('args_in', 'var'))
		args_in = struct();%#ok
	end
	save(path_in, '-struct', 'args_in');
	
	% Execute the command
	msg_in    = cell(3, 1);
	msg_in{1} = client_ID;
	msg_in{2} = class_name;
	msg_in{3} = command;
	msg_out   = send_command(msg_in);

	% Interpret the result
	if(length(msg_out)<1)
		error('Unconsistent answer (no return code)');
	end

	% Code=='OK' => everything went well
	if(strcmp(msg_out{1}, 'OK'))
		args_out = load(path_out);
		return;

	% Code=='Fail' => error while executing the command
	elseif(strcmp(msg_out{1}, 'Fail'))
		error_message = '';
		for p = 2:length(msg_out)
			error_message = sprintf('%s\n  %s', error_message, msg_out{p});
		end
		error('Error while executing the command "%s" with the plugin %s:%s', ...
			command, class_name, error_message);

	% Code=='Bad ID' => try to renew the client ID once
	elseif(strcmp(msg_out{1}, 'Bad ID'))
		if(remaining_attemps>0)
			client_ID = [];
			path_in   = [];
			path_out  = [];
		else
			error('Invalid client ID: %s', client_ID);
		end

	% Code=='Bad class name' => the expected plugin interpreter does not exist on Icy
	elseif(strcmp(msg_out{1}, 'Bad class name'))
		error('The expected plugin (%s) is not installed on Icy', class_name);

	% Unkown return code
	else
		error('Unconsistent answer (unknown return code: %s)', msg_out{1});
	end
end

% Core function
function msg_out = send_command(msg_in)
	
	% Java stuff
	import java.net.Socket
	import java.io.*

	% Establish the connection
	socket = Socket('localhost', 8732);
	out = socket.getOutputStream;
	in  = socket.getInputStream ;

	% Send the list of strings
	for k=1:length(msg_in)
		buffer_in = uint8(sprintf('%s\n', msg_in{k}));
		%fprintf('In: %s', buffer_in);
		out.write(buffer_in);
	end
	out.flush();

	% Wait for the answer and close the connection
	msg_out    = cell(0, 1);
	msg_idx    = 0;
	buffer_out = zeros(1, 256);
	buffer_idx = 0;
	while(true)
		current_char = in.read();
		if(current_char<0)
			error('End of stream reached unexpectedly');
		elseif(current_char==10 || current_char==13)
			current_answer = char(buffer_out(1:buffer_idx));
			%fprintf('Out: %s\n', current_answer);
			if(strcmp(current_answer, 'EOF'))
				break;
			end
			msg_idx = msg_idx + 1;
			msg_out{msg_idx} = current_answer;
			buffer_out = zeros(1, 256);
			buffer_idx = 0;
		else
			buffer_idx = buffer_idx + 1;
			buffer_out(buffer_idx) = current_char;
		end
	end
	socket.close();
end

end
