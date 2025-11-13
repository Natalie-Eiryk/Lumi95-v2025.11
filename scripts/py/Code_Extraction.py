import os

OUTPUT_FILE = "Lumi286_StitchedCode.md"
INCLUDE_EXTENSIONS = {".cpp", ".h", ".hpp", ".cu", ".inl", ".c", ".cc", ".cmake", "CMakeLists.txt"}

def should_include(file):
    ext = os.path.splitext(file)[1]
    return file in INCLUDE_EXTENSIONS or ext in INCLUDE_EXTENSIONS

def collect_files(root_dir):
    stitched_lines = []
    for root, _, files in os.walk(root_dir):
        for file in files:
            if should_include(file):
                file_path = os.path.join(root, file)
                rel_path = os.path.relpath(file_path, root_dir)
                stitched_lines.append(f"\n--- FILE: {rel_path} ---\n")
                try:
                    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                        stitched_lines.extend(f.readlines())
                except Exception as e:
                    stitched_lines.append(f"// Failed to read file: {e}\n")
    return stitched_lines

if __name__ == "__main__":
    root_dir = "."  # Change if running from outside your project root
    lines = collect_files(root_dir)
    with open(OUTPUT_FILE, "w", encoding='utf-8') as out_file:
        out_file.writelines(lines)
    print(f"✅ Code stitched into: {OUTPUT_FILE}")
