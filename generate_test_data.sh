mkdir nf_test_files
cd nf_test_files

for i in $(seq -w 1 100); do
  head -c 1024 </dev/urandom | base64 | head -n 5 > file_${i}.txt
done

# create the Nextflow input list
ls file_*.txt > nf_input.txt

