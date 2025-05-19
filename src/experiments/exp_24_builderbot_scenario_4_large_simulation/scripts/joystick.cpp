#include<iostream>
#include<stdio.h>
#include<string.h>
#include<vector>
#include<map>
#include<fstream>

#include<unistd.h>
#include<fcntl.h>
#include<linux/joystick.h>

#include<sys/socket.h>
#include<netinet/in.h>
#include<arpa/inet.h>

#include<thread>

int axis0 = 0;
int axis1 = 0;
int axis2 = 0;

bool is_record = true;
std::string record_filename = "joystick_record.dat";
std::map<int, std::vector<int>> step_records;  // step -> [axis0, axis1, axis2]

void readRecordFile() {
    std::ifstream file(record_filename);
    if (!file.is_open()) {
        std::cout << "Failed to open file: " << record_filename << std::endl;
        exit(1);
    }
    std::string line;
    while (std::getline(file, line)) {
        int step, a0, a1, a2;
        sscanf(line.c_str(), "%d %d %d %d", &step, &a0, &a1, &a2);
        step_records[step] = {a0, a1, a2};
    }
    file.close();
    std::cout << "Loaded " << step_records.size() << " records from " << record_filename << std::endl;
}

std::vector<int> findNearestRecord(int step) {
    auto it = step_records.lower_bound(step);
    if (it == step_records.end() && !step_records.empty()) {
        return step_records.rbegin()->second;
    }
    return it->second;
}

void listenToJoystick() {
	int joystick = open("/dev/input/js0", O_RDONLY);
	if (joystick < 0)
		std::cout << "joystick open failed\n";

	std::cout << "joystick open success\n";

	struct js_event js;
	
	while (1) {
		int len = read(joystick, &js, sizeof(struct js_event));
		/*
		std::cout << "length = " << len << "\n";
		std::cout << "    time   = " << js.time   << "\n";
		std::cout << "    value  = " << js.value  << "\n";
		std::cout << "    type   = " << js.type   << "\n";
		std::cout << "    number = " << js.number << "\n";
		printf("    time   = %08x\n", js.time);
		printf("    value  = %08x\n", js.value);
		printf("    type   = %08x\n", js.type);
		printf("    number = %08x\n", js.number);
		*/

		// check value
		if (js.type == JS_EVENT_AXIS) {
			switch (js.number)
			{
			case 0:
				axis0 = js.value;
				break;
			case 1:
				axis1 = js.value;
				break;
			case 2:
				axis2 = js.value;
				break;
			}
		}
	}
}

void listenToClient(int client_fd) {
    std::ofstream record_file;
    if (is_record) {
        record_file.open(record_filename, std::ios::app);
    }

    char buffer[1024];
    while (1) {
        memset(&buffer, 0, sizeof(buffer));
        int ret = recv(client_fd, buffer, 1024, 0);
        if (ret <= 0) break;
        
        int step = atoi(buffer);
        char axisbuffer[50];

        if (is_record) {
            sprintf(axisbuffer, "%10d, %10d, %10d\n", axis0, axis1, axis2);
            record_file << step << " " << axis0 << " " << axis1 << " " << axis2 << std::endl;
        } else {
            auto axes = findNearestRecord(step);
            sprintf(axisbuffer, "%10d, %10d, %10d\n", axes[0], axes[1], axes[2]);
        }
        
        send(client_fd, axisbuffer, strlen(axisbuffer), 0);
    }
    if (is_record) {
        record_file.close();
    }
    printf("close client\n");
    close(client_fd);
}

void listenToTcp() {
	int server_fd, client_fd;
	struct sockaddr_in serveraddr, client_addr;

	server_fd = socket(AF_INET, SOCK_STREAM, 0);
	if (server_fd < 0)
		std::cout << "socket creation failed\n";
	
	memset(&serveraddr, 0, sizeof(serveraddr));
	serveraddr.sin_family = AF_INET;
	serveraddr.sin_addr.s_addr = INADDR_ANY;
	serveraddr.sin_port = htons(8080);

	int ret = bind(server_fd, (struct sockaddr*)&serveraddr, sizeof(serveraddr));
	if (ret != 0) {
		std::cout << "bind address failed\n";
		return;
	}

	std::vector<std::thread> client_threads;

	while (1) {
		printf("waiting for a client\n");
		int ret = listen(server_fd, 5);
		socklen_t client_len = sizeof(client_addr);
		client_fd = accept(server_fd, (struct sockaddr*)&client_addr, &client_len);
		printf("client_fd = %d\n", client_fd);
		printf("a client is connected\n");
		client_threads.emplace_back(listenToClient, client_fd);

		sleep(0.1);
	}
}

int main(int argc, char* argv[]) {
    if (argc > 1) {
        is_record = false;
        record_filename = argv[1];
        readRecordFile();
    }

	std::thread threadListenToJoystick(listenToJoystick);
	std::thread threadListenToTcp(listenToTcp);

	threadListenToJoystick.join();
	threadListenToTcp.join();
	return 0;
}