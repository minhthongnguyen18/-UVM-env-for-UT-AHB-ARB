#!/usr/bin/env python3
"""
Test Plan to SystemVerilog Assertion (SVA) Converter
Supports CSV/Excel input, multi-sheet Excel, and assertion-only mode.
"""

import argparse
import sys
import os
from typing import Optional, List
import numpy
import pytz
import dateutil
import pandas as pd

class SVAConverter:
    def __init__(self, clock_signal: str = "clk", reset_signal: str = "reset"):
        self.clock_signal = clock_signal
        self.reset_signal = reset_signal
        self.required_columns = ['condition', 'checkpoint']

    #def clean_condition_checkpoint(self, condition: str, checkpoint: str) -> tuple:
    #    condition = str(condition).strip() if pd.notna(condition) else ""
    #    checkpoint = str(checkpoint).strip() if pd.notna(checkpoint) else ""
    #    return condition.rstrip(';').strip(), checkpoint.rstrip(';').strip()
    
    def clean_condition_checkpoint(self, condition: str, checkpoint: str):
        """
        Cleans condition string, splits out 'Note:' parts.
        Returns (condition_only, checkpoint, note)
        """
        if not condition or not checkpoint:
            return None, None, None
    
        parts = str(condition).split("Note:")
        cond_only = parts[0].strip()
        note = parts[1].strip() if len(parts) > 1 else ""
    
        return cond_only, checkpoint.strip(), note


    def generate_sva(self, condition: str, checkpoint: str) -> str:
        condition, checkpoint = self.clean_condition_checkpoint(condition, checkpoint)
        if not condition or not checkpoint:
            return "// WARNING: Empty condition or checkpoint"
        return f"assert property (@(posedge {self.clock_signal}) disable iff ({self.reset_signal}) {condition} |-> {checkpoint});"

    def is_marked_for_conversion(self, value) -> bool:
        if pd.isna(value):
            return False
        # normalize to string, strip, lowercase
        val = str(value).strip().lower()
        if val in ['yes', 'y', 'true', 'convert', 'enable', 'enabled', '1']:
            return True
        # handle numeric 1 (int or float)
        try:
            return float(val) == 1.0
        except ValueError:
            return False


    def process_dataframe(self, df: pd.DataFrame, marking_column: str,
                          sort_column: Optional[str] = None) -> pd.DataFrame:
        # validate
        all_required = self.required_columns + [marking_column]
        missing = [c for c in all_required if c not in df.columns]
        if missing:
            raise ValueError(f"Missing required columns: {missing}")

        if sort_column and sort_column in df.columns:
            df = df.sort_values(by=sort_column).reset_index(drop=True)

        df['sva_assertion'] = ""
        for idx, row in df.iterrows():
            if self.is_marked_for_conversion(row[marking_column]):
                df.at[idx, 'sva_assertion'] = self.generate_sva(row['condition'], row['checkpoint'])
            else:
                df.at[idx, 'sva_assertion'] = "// Not marked for conversion"
        return df

    #def generate_assertions_only(self, df: pd.DataFrame, marking_column: str) -> List[str]:
    #    """
    #    Generate only assertions as a list of strings.
    #    """
    #    assertions = []
    #    for _, row in df.iterrows():
    #        if self.is_marked_for_conversion(row[marking_column]):
    #            assertions.append(self.generate_sva(row['condition'], row['checkpoint']))
    #    return assertions
    
    def generate_assertions_only(self, df: pd.DataFrame, marking: Optional[str] = None) -> str:
        assertions = []
        for _, row in df.iterrows():
            # Apply marking filter
            if marking and str(row.get("convert_to_sva", "")).strip() != "1":
                continue
    
            cond_only, checkpoint, note = self.clean_condition_checkpoint(
                str(row.get("check in condition", "")),
                str(row.get("checkpoint", ""))
            )
    
            if cond_only and checkpoint:
                sva = f"""
    // Assertion for: {checkpoint}
    assert property (@(posedge {self.clock_signal}) disable iff (!{self.reset_signal})
        {cond_only} |-> {checkpoint}
    ) else $error("Assertion failed: {checkpoint}");
    """
                if note:
                    for line in note.splitlines():
                        line = line.strip()
                        if line:
                            sva += f"// {line}\n"
                assertions.append(sva)
                
        print("Row data:", row.to_dict())
        print("convert_to_sva:", row.get("convert_to_sva", "N/A"))
        print("condition:", row.get("check in condition", ""))
        print("checkpoint:", row.get("checkpoint", ""))

        return "\n".join(assertions)

    def load_from_file(self, filepath: str, sheet: Optional[str] = None) -> pd.DataFrame:
        if not os.path.exists(filepath):
            raise FileNotFoundError(f"File not found: {filepath}")

        ext = os.path.splitext(filepath)[1].lower()
        if ext == ".csv":
            return pd.read_csv(filepath)
        elif ext in [".xlsx", ".xlsm"]:
            if sheet:
                return pd.read_excel(filepath, sheet_name=sheet, engine="openpyxl")
            else:
                return pd.read_excel(filepath, sheet_name=0, engine="openpyxl")  # first sheet
        else:
            raise ValueError(f"Unsupported file format: {ext}")


def main():
    parser = argparse.ArgumentParser(description="Convert test plan to SystemVerilog Assertions (SVA)")
    parser.add_argument('--input', '-i', type=str, help='Input CSV/Excel file path')
    parser.add_argument('--output', '-o', type=str, help='Output file path')
    parser.add_argument('--marking', '-m', type=str, default='convert_to_sva',
                        help='Marking column (default: convert_to_sva)')
    parser.add_argument('--sort', '-s', type=str, help='Optional column name to sort by')
    parser.add_argument('--sheet', type=str, help='Excel sheet name (default: first sheet)')
    parser.add_argument('--clock', type=str, default='clk', help='Clock signal name')
    parser.add_argument('--reset', type=str, default='rst_n', help='Reset signal name')
    parser.add_argument('--assert-only', action='store_true',
                        help='Generate assertions only (list, no DataFrame)')
    args = parser.parse_args()

    if not args.input:
        parser.error("You must provide --input")

    converter = SVAConverter(clock_signal=args.clock, reset_signal=args.reset)
    df = converter.load_from_file(args.input, sheet=args.sheet)

    if args.assert_only:
        assertions = converter.generate_assertions_only(df, args.marking)
        if args.output:
            with open(args.output, "w") as f:
                for a in assertions:
                    f.write(a + "\n")
            print(f"✓ Saved {len(assertions)} assertions to {args.output}")
        else:
            print("\n".join(assertions))
    else:
        result_df = converter.process_dataframe(df, args.marking, args.sort)
        if args.output:
            ext = os.path.splitext(args.output)[1].lower()
            if ext in [".xlsx", ".xlsm"]:
                result_df.to_excel(args.output, index=False, engine="openpyxl")
            else:
                result_df.to_csv(args.output, index=False)
            print(f"✓ Saved results to {args.output}")
        else:
            print(result_df[['condition', 'checkpoint', 'sva_assertion']])


if __name__ == "__main__":
    sys.exit(main())
