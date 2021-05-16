#!/usr/bin/env python3

import argparse
import itertools
import os
import shutil
import os.path as path
from pathlib import Path
from typing import List, Dict
from SpectrumSDTConfig import SpectrumSDTConfig


def parse_command_line_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Creates a folder structure for a given value of K, copies config template to the target folders, and fills out placeholder values. "
            "Placeholder values can be referred to in config template as {parameter}, where parameter name can be one of: K, symmetry, stage or parity (if K is a range).")
    parser.add_argument("-c", "--config", default="spectrumsdt.config", help="Path to a template configuration file. ./spectrumsdt.config by default.")
    parser.add_argument("-K", required=True, help="The value of K for which to generate the folder structure. "
    "Can either be a scalar, a custom range in the form K1..K2, or 'all' to include all Ks for a given J and parity.")
    parser.add_argument("--extra", help="A dictionary with extra placeholder values that are applied to all target folders.")
    args = parser.parse_args()
    return args


def resolve_defaults(args: argparse.Namespace):
    if args.extra is None:
        args.extra = {}
    else:
        args.extra = eval(args.extra)
        for key, value in args.extra.items():
            if not isinstance(value, str):
                args.extra[key] = str(value)


def generate_paths(base_path: str, param_names: List[str], use_param_names: List[bool], value_combos) -> List[str]:
    """ Generates all config paths for all combination of values of all parameters. """
    all_paths = []
    for i in range(len(value_combos)):
        next_path = base_path
        next_combo = value_combos[i]
        for j in range(len(next_combo)):
            if use_param_names[j]:
                next_path = path.join(next_path, param_names[j] + "_" + next_combo[j])
            else:
                next_path = path.join(next_path, next_combo[j])
        all_paths.append(next_path)
    return all_paths


def create_paths(target_paths: List[str]):
    """ Creates all paths specified in target_paths. """
    for next_path in target_paths:
        next_path = Path(next_path)
        if next_path.name == "basis" or next_path.name == "overlaps" or next_path.name == "eigensolve":
            next_path = next_path / ("out_" + next_path.name)
        if not path.exists(next_path):
            os.makedirs(next_path)


def multicopy_config(config_path: str, target_paths: List[str]) -> List[str]:
    """ Copies specified config file into specified list of directories. """
    for target_path in target_paths:
        shutil.copyfile(config_path, path.join(target_path, "spectrumsdt.config"))


def generate_param_dicts(param_names: List[str], value_combos, extra: Dict[str, str]) -> List[Dict[str, str]]:
    """ Transforms lists of names and value combinations to list of dictionaries. """
    res = []
    for i in range(len(value_combos)):
        next_dict = {}
        for j in range(len(value_combos[i])):
            next_dict[param_names[j]] = value_combos[i][j]
        next_dict.update(extra)
        res.append(next_dict)
    return res


def set_placeholder_params(target_paths: List[str], param_dicts: List[Dict[str, str]]):
    """ Iterates over configs at *target_paths* and sets placeholder params according to *param_dicts*. """
    for i in range(len(target_paths)):
        with open(path.join(target_paths[i], "spectrumsdt.config"), "r+") as config:
            content = config.read()
            formatted = content.format(**param_dicts[i])
            config.seek(0)
            config.write(formatted)
            config.truncate()


def main():
    args = parse_command_line_args()
    resolve_defaults(args)
    config_path = path.abspath(args.config)
    config = SpectrumSDTConfig(config_path)

    param_names = ["K", "symmetry", "stage"]
    use_param_names = [True, True, False]
    param_values = [[args.K], ["0", "1"], ["eigensolve", "properties"]]

    # both symmetries are used when geometric phase effects are enabled
    if "use_geometric_phase" in config.params and config.params["use_geometric_phase"] == "1":
        param_values[1] = ["all"]

    if args.K.isdigit():
        do_basis = False
        if "fixed" in config.params["basis"]:
            J = int(config.params["J"])
            K = int(args.K)
            fixed_J = int(config.params["basis"]["fixed"]["J"])
            fixed_K = int(config.params["basis"]["fixed"]["K"])
            if J == fixed_J and K == fixed_K:
                do_basis = True
        else:
            do_basis = True

        if do_basis:
            # add extra stages if K is necessary
            param_values[2].insert(0, "basis")
            param_values[2].insert(1, "overlaps")

    else:
        # add parity param if K is a range
        param_names.insert(1, "parity")
        use_param_names.insert(1, True)
        param_values.insert(1, ["0", "1"])
    value_combos = list(itertools.product(*param_values))

    base_path = path.dirname(config_path)
    target_paths = generate_paths(base_path, param_names, use_param_names, value_combos)
    create_paths(target_paths)
    multicopy_config(config_path, target_paths)

    param_dicts = generate_param_dicts(param_names, value_combos, args.extra)
    set_placeholder_params(target_paths, param_dicts)


if __name__ == "__main__":
    main()
