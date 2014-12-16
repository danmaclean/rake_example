Dir.glob('lib/*.rakefile').each { |r| import r }
require_relative 'lib/os.rb'
require 'json'




desc "combines :make_input_files, :make_binaries, :install_binaries"
task :setup do
  Rake::Task["make_input_files"].invoke 
  Rake::Task["make_binaries"].invoke 
  Rake::Task["install_binaries"].invoke
  Rake::Task["make_blast_db"].invoke
end

desc "makes results/ directory"
directory "results"

desc "makes tmp/ directory"
directory "tmp"

desc "makes tmp/no_snp_reads.txt reads input file for cortex"
file "tmp/no_snp_reads.txt" => ["tmp","left.fq", "right.fq"]  do
  File.open("tmp/no_snp_reads.txt", "w") do |f|
    f.puts ["left.fq 0", "right.fq 0"].join("\n")
  end
end

desc "makes tmp/snp_reads.txt reads input file for cortex"
file "tmp/snp_reads.txt" => ["tmp", "snps_left.fq", "snps_right.fq"] do
  File.open("tmp/snp_reads.txt", "w") do |f|
    f.puts ["snps_left.fq 0", "snps_right.fq 0"].join("\n")
  end
end

desc "runs cortex and makes graph file from tmp/snp_reads.txt"
file "tmp/snps.ctx" => ["tmp/snp_reads.txt"] do
  sh "bin/cortex_bub_95 -k #{@k} -n #{@n} -b #{@b} -t fastq -c #{@c} -s #{@s} -i tmp/snp_reads.txt -o tmp/snps.ctx -l tmp/snps.log"
end

desc "runs cortex and makes graph file from tmp/no_snp_reads.txt"
file "tmp/no_snps.ctx" => ["tmp/no_snp_reads.txt"] do
  sh "bin/cortex_bub_95 -k #{@k} -n #{@n} -b #{@b} -t fastq -c #{@c} -s 1 -i tmp/no_snp_reads.txt -o tmp/no_snps.ctx -l tmp/no_snps.log"
end

desc "makes both ctx graph files"
task :make_ctx do
  Rake::Task["tmp/no_snps.ctx"].invoke
  Rake::Task["tmp/snps.ctx"].invoke
end

desc "makes cortex file of files tmp/ctxlist.txt"
file "tmp/ctxlist.txt" => ["tmp/no_snps.ctx", "tmp/snps.ctx"] do
    File.open("tmp/ctxlist.txt", "w") do |f|
      f.puts ["tmp/no_snps.ctx 0", "tmp/snps.ctx 1"].join("\n")
    end
end

desc "runs cortex_bub"
file "tmp/bubbles.coverage" => ["tmp/no_snps.ctx", "tmp/snps.ctx", "tmp/ctxlist.txt"] do
  sh "bin/cortex_bub_95 -k #{@k} -n #{@n} -b #{@b} -t binary -w #{@w} -i tmp/ctxlist.txt -f tmp/bubbles -l bubbles.log"
end

file "tmp/bubbles.fasta" do
  Rake::Task["tmp/bubbles.coverage"].invoke
end

task :make_bubbles do
  Rake::Task["tmp/bubbles.coverage"].invoke
end

file "tmp/bpoptions.txt" do
  File.open("tmp/bpoptions.txt", "w") do |f|
    f.puts ['EXPECTEDCOVERAGE "0,10,100,0"', 'EXPECTEDCOVERAGE "1,10,100,0" ', 'MINIMUMCONTIGSIZE "100"'].join("\n")
  end
end

file "tmp/allfiles.txt" do
  File.open("tmp/allfiles.txt", "w") do |f|
    f.puts ["left.fq 1", "right.fq 1", "snps_left.fq 0", "snps_right.fq 0"].join("\n")
  end
end

file "results/results.csv" => ["results", "tmp/allfiles.txt", "tmp/bpoptions.txt", "tmp/bubbles.coverage", "tmp/bubbles.fasta"] do
  sh "bin/bubbleparse_95 -k #{@k} -o tmp/bpoptions.txt -f tmp/bubbles -i tmp/allfiles.txt -t results/results.txt -c results/results.csv -d bplog.txt -x"
end 

task :rank_bubbles do 
  Rake::Task["results/results.csv"].invoke
end

desc "draws a PDF of the files and dependencies and tasks that create them"
task :draw_tasks do
  sh %{ruby lib/draw_tasks.rb Rakefile}
end

desc "matches bubbles and known snps by blasting bubbleparse match to original seq"
file "results/bubbles_matched_to_snps.csv" => ["results/results.csv", "tmp/bubbles.fasta", "tmp/bubbles.coverage", "log/added_snps.log"] do
  sh "perl lib/analyse_bubbles.pl --csv results/results.csv --fasta tmp/bubbles.fasta --coverages tmp/bubbles.coverage --known_snps log/added_snps.log --wgsim_snps_original log/wgsim_snps_original_sequence.log --wgsim_snps_mutated log/wgsim_snps_mutated_sequence.log --run_details log/run_details.json"
end



