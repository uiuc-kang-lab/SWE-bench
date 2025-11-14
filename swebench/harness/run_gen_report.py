from swebench.harness.log_parsers import MAP_REPO_TO_PARSER
import argparse
import os, json

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Parse a SWE-bench log file and output the test status map."
    )
    parser.add_argument(
        "--test_patch_file",
        type=str,
        help="Path to the test patch file.",
    )
    parser.add_argument(
        "--log_dir",
        type=str,
        help="Directory containing the log files.",
    )
    parser.add_argument(
        "--output_file",
        type=str,
        help="Path to the output report file.",
    )

    args = parser.parse_args()
    test_patch_file = args.test_patch_file
    log_dir = args.log_dir
    output_file = args.output_file
    
    results = {}
    with open(test_patch_file, 'r') as f:
        test_patches = [json.loads(line) for line in f.readlines()]

    for test_patch in test_patches:
        instance_id = test_patch['instance_id']
        results[instance_id] = {
            "n_resolved_tests": 0,
            "n_unresolved_tests": 0,
            "n_missing_tests": 0,
            "details": {
                "resolved": [],
                "unresolved": [],
                "missing": []
            }
        }
        log_file = os.path.join(log_dir, instance_id, 'test_output.txt')
        if not os.path.exists(log_file):
            print(f"Log file does not exist: {log_file}")
            continue
        repo_name = '/'.join('-'.join(instance_id.split('-')[:-1]).split('__'))
        parser_class = MAP_REPO_TO_PARSER[repo_name]
        with open(log_file, 'r') as f:
            log_content = f.read()
            test_status = parser_class(log_content, None)
            
        for test_name in test_patch['test_names']:
            if test_name.strip() == "":
                continue
            found = False
            for logged_test_name, status in test_status.items():
                if logged_test_name.endswith(test_name):
                    if status == 'PASSED':
                        print(f"{instance_id}:{test_name}: PASS.")
                        results[instance_id]["n_resolved_tests"] += 1
                        results[instance_id]["details"]["resolved"].append(test_name)
                    else:
                        print(f"{instance_id}:{test_name}: FAIL.")
                        results[instance_id]["n_unresolved_tests"] += 1
                        results[instance_id]["details"]["unresolved"].append(test_name)
                    found = True
                    break
            if not found:
                print(f"{instance_id}:{test_name}: Test case not found in log.")
                results[instance_id]["n_missing_tests"] += 1
                results[instance_id]["details"]["missing"].append(test_name)

    with open(output_file, 'w') as f:
        json.dump(results, f, indent=4)