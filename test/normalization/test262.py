import argparse
from pathlib import Path
import subprocess

test_root = None
USE_STRICT = "\"use strict\";\n"
TO_PROCESS = ["tests/language/expressions/", "tests/language/statements/"]
TIME_OUT = 10

# colors
RED = "\033[91m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
RESET = "\033[0m"

# info
TOUT = "tout"
PASS = "pass"
FAIL = "fail"

# analysis information
total = 0
norm_error = 0
smnt_error = 0 
timeout = 0
ok = 0 

def simplify_path (path):
    return path.relative_to(test_root/"tests/language")

def test_output (failed, path, color, normalization, semantics):
    failed = "NOK" if failed else "OK " 
    print(f"[{failed}] {simplify_path(path)}\t norm [{normalization}]\tsemantics [{semantics}]")


def normalize(path):
    try:
        # run normalization
        result = subprocess.run(["ast_gen", path], capture_output=True, text=True, check=True, timeout=TIME_OUT)
        norm_program = result.stdout
        
        return PASS, norm_program
    except subprocess.CalledProcessError:
        info = FAIL
    except subprocess.TimeoutExpired:
        info = TOUT

    return info, None


def test(program):
    try:
        result = subprocess.run(["node", "-e", program], capture_output=True, text=True, check=True, timeout=TIME_OUT)
        if result.stderr:
            print(result.stderr)

        return PASS, ""
    except subprocess.CalledProcessError as e:
        info = FAIL
        error = e.stderr + "\n"
    except subprocess.TimeoutExpired:
        info = TOUT
        error = ""

    return info, error

def main():
    global test_root
    global total, norm_error, smnt_error, ok, timeout

    # setup command line interface
    parser = argparse.ArgumentParser(description="test normalization against test262 test suite")
    parser.add_argument("test_root", type=str, help="path to the test262 test suite root")
    args = parser.parse_args()
    
    test_root = Path(args.test_root)
    # get harness
    with open(f"{test_root}/environment/harness.js") as file:
        harness = file.read()

    # run all tests
    for test_dir in TO_PROCESS:
        for path in (test_root/test_dir).rglob("*"):
            if path.is_file():
                total += 1

                # preprocess file 
                with open(path) as file:
                    content = file.read()
                    is_negative = content.find("negative:") != -1
                    negative = "NEGATIVE - " if is_negative else ""
                    is_strict   = content.find("onlyStrict") != -1

                # normalize + test program 
                test_info, test_error = "", ""
                norm_info, norm_prog = normalize(path)
                if norm_prog:
                    test_prog = (USE_STRICT if is_strict else "") + harness + "\n" + norm_prog 
                    test_info, test_error = test(test_prog) 

                # output report
                failed  = (norm_info == FAIL or test_info == FAIL)
                concrete_fail = failed != is_negative
                timed_out = (norm_info == TOUT or test_info == TOUT)
                color = YELLOW
                if concrete_fail:
                    color = RED
                    norm_error += norm_info == FAIL
                    smnt_error += test_info == FAIL
                else:
                    color = GREEN
                    ok += 1
                
                timeout += timed_out
                test_output(concrete_fail or timed_out, path, color, norm_info, test_info)
                if not is_negative:
                    print(test_error, end="")

    # report
    print("==============================")
    print(f"total : {total}")
    print(f"ok    : {ok}")
    print(f"error : {norm_error}/{smnt_error} (normalization/semantics)")
    print(f"timeout : {timeout}")
    print("=============================")


    #run_node_script(f"{test262_root}/tests/language/expressions/array/11.1.4-0.js" )

if __name__ == "__main__":
    main()
