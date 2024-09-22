CC_AFL=$(AFL_PATH)afl-clang
ASAN_FLAG=-fsanitize=address
DEBUG_CFLAGS=$(ASAN_FLAG) -g
COV_FLAG_GCC=--coverage
COV_FLAG_CLANG=-fprofile-instr-generate -fcoverage-mapping
CFLAGS=-O2
LDFLAGS=-lreadline 
BIN=bin
TARGET=main.c
TARGET_LIB=lib


help:
	@echo "Available targets:"
	@echo "  build           	 : Build the main application"
	@echo "  debug           	 : Build the application with AFL and ASAN for debugging"
	@echo "  clean           	 : Remove object files"
	@echo "  fuzz            	 : Run AFL fuzzing sessions"
	@echo "  coverage       	 : Generate code coverage report with gcc and lcov"
	@echo "  coverage_clang      : Generate code coverage report with clang and llvm-cov"
	
	
build: 
	$(CC) -c $(TARGET) $(CFLAGS) -o main.o
	$(CC) -c $(TARGET_LIB)/*.c $(CFLAGS) -o lib.o
	$(CC) main.o lib.o $(LDFLAGS) -o $(BIN) 
	rm *.o
 
debug: 
	$(CC_AFL) -c $(DEBUG_CFLAGS) $(TARGET)  -o main.o -Wall -Wextra 
	$(CC_AFL) -c $(DEBUG_CFLAGS) $(TARGET_LIB)/*.c -o lib.o -Wall -Wextra 
	$(CC_AFL) main.o lib.o $(LDFLAGS) $(ASAN_FLAG) -o $(BIN)_asan
	rm *.o

fuzz: debug
	rm -rf in out
	mkdir in out
	echo 1 >> in/1
	echo "l" >> in/2
	echo "ф" >> in/3
	tmux new-session -d -s my_session -n Window1 '$(AFL_PATH)afl-fuzz -i in -o out -M master -x utf8.dict -- ./$(BIN)_asan'
	tmux new-window -t my_session:1 -n Window2 '$(AFL_PATH)afl-fuzz -i in -o out -S slave1 -x utf8.dict -- ./$(BIN)_asan'
	tmux new-window -t my_session:2 -n Window3 '$(AFL_PATH)afl-fuzz -i in -o out -S slave2 -x utf8.dict -- ./$(BIN)_asan'
	tmux new-window -t my_session:3 -n Window4 '$(AFL_PATH)afl-fuzz -i in -o out -S slave3 -x utf8.dict -- ./$(BIN)_asan'
	tmux select-window -t my_session:0
	tmux attach-session -t my_session

coverage_build_gcc:
	gcc -c $(COV_FLAG_GCC) $(TARGET) -o main.o 
	gcc -c $(COV_FLAG_GCC) $(TARGET_LIB)/*.c -o lib.o 
	gcc main.o lib.o $(LDFLAGS) $(COV_FLAG_GCC) -o $(BIN)_cov
	rm *.o

coverage_gcc: coverage_build_gcc
	rm -rf coverage_report
	./get_cover.sh
	lcov -t "lab4" -o lab4.info -c -d .
	genhtml -o coverage_report lab4.info



coverage_build_clang:
	clang -c $(COV_FLAG_CLANG) $(TARGET) -o main.o 
	clang -c $(COV_FLAG_CLANG) $(TARGET_LIB)/*.c -o lib.o 
	clang main.o lib.o $(LDFLAGS) $(COV_FLAG_CLANG) -o $(BIN)_cov
	rm *.o

coverage_clang: coverage_build_clang
	rm -rf coverage_report_clang
	./get_cover.sh
	llvm-profdata merge -sparse default.profraw -o foo.profdata
	llvm-cov show  $(BIN)_cov -instr-profile=foo.profdata
	llvm-cov report $(BIN)_cov -instr-profile=foo.profdata
	llvm-cov show $(BIN)_cov -instr-profile=foo.profdata -format=html -output-dir=coverage_report_clang
	rm foo.profdata default.profraw 


coverage_build: coverage_build_gcc

coverage: coverage_gcc

clean:
	rm -rf in $(BIN)* *.gcno *.gcda  *.info foo.profdata default.profraw 
