import argparse
from pathlib import Path
import os
import subprocess
import timeit


TIMEOUT = 10
OUTPUT_PATH = "out"

# paths
TESTS = "tests"
ENVIRONMENT = "environment"
HARNESS = f"{ENVIRONMENT}/harness.js"

# info
TOUT = "tout"
PASS = "pass"
FAIL = "fail"

# error info
TOTAL      = "total"
OK         = "ok"
NORM_E     = "norm_e"
SMNT_E     = "smnt_e"
TIMED_OUT   = "timed_out"
CUMULATIVE = "cumulative"

# time info
TIME = "total_time"
NORMALIZED = "normalized"


# colors
RED = "\033[91m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
RESET = "\033[0m"

def graphjs_command(path):
    return ["python3", "../../graphjs/graphjs_old.py", "-f", path, "-o", OUTPUT_PATH, "--norm_only"]

def graphjs2_command(path):
    return ["graphjs2", path, "-o", OUTPUT_PATH]

def normalize(path, command, output_folder):
    try:
        # run normalization
        execution_time = timeit.timeit(lambda: subprocess.run(command(path), capture_output=True, text=True, check=True, timeout=TIMEOUT), number=1)
        output_file = f"{output_folder}/{os.path.basename(path)}"

        if not os.path.exists(output_file):
            return "no output file", FAIL, None, None
        
        with open(output_file, "r") as file:
            norm_program = file.read()
            
        return "", PASS, norm_program, execution_time
    except subprocess.CalledProcessError as e:
        info = FAIL
        error = e.stderr + "\n"
    except subprocess.TimeoutExpired:
        info = TOUT
        error = ""

    return error, info, None, None



def test(program):
    try:
        result = subprocess.run(["node", "-e", program], capture_output=True, text=True, check=True, timeout=TIMEOUT)
        if result.stderr:
            print(result.stderr)

        return "", PASS
    except subprocess.CalledProcessError as e:
        info = FAIL
        error = e.stderr + "\n"
    except subprocess.TimeoutExpired:
        info = TOUT
        error = ""

    return error, info

def update_info (info, group, key, value):
    info[group][key] += value
    info[CUMULATIVE][key] += value

def update_test_info(info, out_file, test_group, file_name ,is_negative, norm_info, norm_error, test_info, test_error, total):
    failed  = (norm_info == FAIL or test_info == FAIL)
    concrete_fail = failed != is_negative
    timed_out = (norm_info == TOUT or test_info == TOUT)
    
    if timed_out:
        update_info(info, test_group, TIMED_OUT, 1)
        color = YELLOW
    elif concrete_fail:
        negative = FAIL if not is_negative else PASS
        update_info(info, test_group, NORM_E, norm_info == negative)
        update_info(info, test_group, SMNT_E, test_info == negative)
        color = RED
    else:
        update_info(info, test_group, OK, 1)
        color = GREEN

    # count 
    count = f"({info[CUMULATIVE][TOTAL]}/{total})"

    # print test info
    failed = "NOK" if concrete_fail or timed_out else "OK "
    message = f"{count} [{failed}] {file_name}\t norm [{norm_info}]\tsemantics [{test_info}]"
    print(f"{color}{message}{RESET}")
    
    if concrete_fail or timed_out:
        out_file.write(message + "\n")
        out_file.write("\t" + norm_error.replace("\n", "\n\t")[::-1].replace("\t\n", "\n", 1)[::-1] if norm_error != "" else norm_error)
        out_file.write("\t" + test_error.replace("\n", "\n\t")[::-1].replace("\t\n", "\n", 1)[::-1] if test_error != "" else test_error)

def report(info, out_file):
    for key in info:
        if key == CUMULATIVE:
            continue
        
        time_avg = (info[key][TIME] / info[key][NORMALIZED]) * 1000
        ok_percentage = round(info[key][OK] / info[key][TOTAL] * 100, 1)
        message = f"(PASSED {ok_percentage}%)\t{key}\t failed : {info[key][NORM_E]}/{info[key][SMNT_E]}   timeout : {info[key][TIMED_OUT]}    time : {time_avg:.5}ms"
        print(message)
        out_file.write(message + "\n") 
    
    # cumulative report
    message = f"""
    ==============================
    total : {info[CUMULATIVE][TOTAL]}
    ok    : {info[CUMULATIVE][OK]}
    error : {info[CUMULATIVE][NORM_E]} + {info[CUMULATIVE][SMNT_E]} (normalization + semantics)
    timeout : {info[CUMULATIVE][TIMED_OUT]}
    time : {(info[key][TIME] / info[key][NORMALIZED]) * 1000:.5}ms
    ==============================
    """
    print(message)
    out_file.write(message + "\n")


def parse_arguments():
    parser = argparse.ArgumentParser(description="test normalization against test262 test suite")
    parser.add_argument("test_root", type=str, help="path to the test262 test suite root")
    parser.add_argument("output"   , type=str, help="output file")
    parser.add_argument("tool", type=str, choices=["graphjs", "graphjs2"], help="choose the tool to test")

    return parser.parse_args()

def empty_info():
    return {
        TOTAL      : 0,
        NORM_E     : 0,
        SMNT_E     : 0, 
        TIMED_OUT  : 0,
        OK         : 0,
        TIME       : 0,
        NORMALIZED : 0, 
    }

def main():
    global NORM_CODE_DIR

    # error information setup
    info = {CUMULATIVE : empty_info()}

    # setup command line interface
    args = parse_arguments()
    test_root = Path(args.test_root)
    output = Path(args.output)
    total = len(list(Path(test_root / TESTS).rglob("*.js")))

    # setup tool
    if args.tool == "graphjs":
        command = graphjs_command
        output_folder = f"{OUTPUT_PATH}/graph"
    elif args.tool == "graphjs2":
        command = graphjs2_command
        output_folder = f"{OUTPUT_PATH}/code"

    # get harness
    with open(test_root / HARNESS) as file:
        harness = file.read()

    # run all tests
    with open(output, "w") as out_file:
        for path in (test_root / TESTS).rglob("*"):
            if path.is_file():
                file_name  = path.relative_to(test_root / TESTS).__str__()

                # more detailed information for each test group (statement/array, ...)
                test_group = path.parent.relative_to(test_root / TESTS).__str__()
                if test_group not in info:
                    info[test_group] = empty_info()
                update_info(info, test_group, TOTAL, 1)

                # preprocess file 
                with open(path) as file:
                    content = file.read()
                    is_negative = content.find("negative:") != -1
                    is_strict   = content.find("onlyStrict") != -1

                # normalize + test program 
                test_info, test_error = "", ""
                norm_error, norm_info, norm_prog, exec_time = normalize(path, command, output_folder)
                if exec_time:
                    update_info(info, test_group, TIME, exec_time)
                    update_info(info, test_group, NORMALIZED, 1)

                if norm_prog:
                    test_prog = ("\"use strict\";\n" if is_strict else "") + harness + "\n" + norm_prog 
                    test_error, test_info = test(test_prog) 

                
                update_test_info(info, out_file, test_group, file_name, is_negative, norm_info, norm_error, test_info, test_error, total)

        # output detailed report
        report(info, out_file)
    
    os.system(f"rm -fr {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
