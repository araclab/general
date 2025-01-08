#!/usr/bin/env python3

"""
cgMLST main script

Contributors:
C. Johnsen
P. Clausen
K. Therkelsen

"""
version_numb = "v1.2.0"

# imports
import os, sys, shutil, subprocess, shlex, pickle, re, gzip, time, json
from argparse import ArgumentParser
from ete3 import Tree
from difflib import ndiff
import hashlib


# for help
if len(sys.argv) == 1:
    print ("")
    print ("cgMLST - Assigns core genome MLST alleles based ")
    print (version_numb)
    print ("Used with KMA")
    print ("")
    print ("Usage: cgMLST.py <options> ")
    print ("Ex: cgMLST.py -i /path/to/isolate.fa.gz -s salmonella -db /path/to/cgmlstfinder_db/ -o /path/to/outdir")
    print ("Ex: cgMLST.py -i /path/to/isolate_1.fa.gz,/path/to/isolate_2.fa.gz -s salmonella -db /path/to/cgmlstfinder_db/ -o /path/to/outdir")
    print ("")
    print ("")
    print ("For help, type: cgMLST.py -h")
    print ("")
    sys.exit(1)
    
    ##########################################################################
    # CLASSES AND FUNCTIONS                                                  #   
    ##########################################################################

class SeqFile():
    """ """
    def __init__(self, seqfile, pe_file_reverse=None, phred_format=None):
        """ Constructor.
        """
        self.phred = phred_format

        seqfile = os.path.abspath(seqfile)
        if(not os.path.isfile(seqfile)):
            print("File not found: " + seqfile)
            sys.exit(1)
        self.path = seqfile
        self.pe_file_reverse = None

        self.filename = SeqFile.get_read_filename(seqfile)
        self.filename_reverse = None

        self.trim_path = None
        self.trim_pe_file_reverse = None

        self.gzipped = SeqFile.is_gzipped(seqfile)

        if(pe_file_reverse):
            self.seq_format = "paired"

            # Add path to reverse pair file
            self.pe_file_reverse = os.path.abspath(pe_file_reverse)
            if(not os.path.isfile(pe_file_reverse)):
                print("Reverse pair file not found: \"" + pe_file_reverse
                      + "\"")
                sys.exit(1)
            self.path_reverse = pe_file_reverse

            self.filename_reverse = SeqFile.get_read_filename(
                self.pe_file_reverse)

            # Check if pair is gzipped
            if(self.gzipped != SeqFile.is_gzipped(pe_file_reverse)):
                print("ERROR: It seems that only one of the read pair files is\
                      gzipped.")
                sys.exit(1)
        elif(phred_format):
            self.seq_format = "single"
        else:
            self.seq_format = "assembly"

    def set_trim_files(self, path, path_reverse=None):
        self.trim_path = path
        self.trim_filename = SeqFile.get_read_filename(path)
        if(path_reverse):
            self.trim_pe_file_reverse = path_reverse
            self.trim_filename_reverse = SeqFile.get_read_filename(
                path_reverse)

    @staticmethod
    def get_read_filename(seq_path):
        """ Removes path from given string and removes extensions:
            .fq .fastq .gz and .trim
        """
        seq_path = os.path.basename(seq_path)
        seq_path = seq_path.replace(".fq", "")
        seq_path = seq_path.replace(".fastq", "")
        seq_path = seq_path.replace(".gz", "")
        seq_path = seq_path.replace(".trim", "")
        seq_path = seq_path.replace(".fa", "")
        seq_path = seq_path.replace(".fasta", "")
        seq_path = seq_path.replace(".fna", "")
        seq_path = seq_path.replace(".trim", "")        
        return seq_path.rstrip()

    @staticmethod
    def is_gzipped(file_path):
        """ Returns True if file is gzipped and False otherwise.

            The result is inferred from the first two bits in the file read
            from the input path.
            On unix systems this should be: 1f 8b
            Theoretically there could be exceptions to this test but it is
            unlikely and impossible if the input files are otherwise expected
            to be encoded in utf-8.
        """
        with open(file_path, mode="rb") as fh:
            bit_start = fh.read(2)
        if(bit_start == b"\x1f\x8b"):
            return True
        else:
            return False

    @staticmethod
    def group_fastqs(file_paths):
        """
        """

        re_filename = re.compile(r"(.+)_S\d+_L(\d+)(_.+)")
        re_seqdb_filename = re.compile(r"([E|S]RR\d+)(_\d+?\..+)")
        file_groups = {}

        for path in file_paths:

            filename = os.path.basename(path)
            match_filename = re_filename.search(filename)
            match_seqdb = re_seqdb_filename.search(filename)

            if(match_filename):
                name = match_filename.group(1)
                lane_no = match_filename.group(2)
                pair_id = match_filename.group(3)
                lane_no = int(lane_no)
                lane_nos = file_groups.get((name, pair_id), {})
                lane_nos[lane_no] = path
                file_groups[(name, pair_id)] = lane_nos
            elif(match_seqdb):
                # Assume that no lane number exist and are just provided an
                # artificial lane number.
                name = match_seqdb.group(1)
                lane_no = 1
                pair_id = match_seqdb.group(2)
                lane_nos = file_groups.get((name, pair_id), {})
                lane_nos[lane_no] = path
                file_groups[(name, pair_id)] = lane_nos
            else:
                print("Warning: Did not recognise filename: " + filename)

        return file_groups

    @staticmethod
    def concat_fastqs(file_paths, out_path=".", verbose=False):
        """
        """

        out_list = []
        file_groups = SeqFile.group_fastqs(file_paths)

        for (name, pair_id), lane_nos in file_groups.items():

            out_filename = SeqFile.get_read_filename(name + pair_id) + ".fq"
            sorted_lanes = sorted(lane_nos.keys())

            for lane_no in sorted_lanes:
                path = lane_nos[lane_no]
                if(SeqFile.is_gzipped(path)):
                    cmd = "gunzip -c "
                else:
                    cmd = "cat "
                cmd += path + " >> " + out_path + "/" + out_filename
                subprocess.Popen(cmd, shell=True) 
            subprocess.Popen("gzip " + out_path + "/" + out_filename, shell=True)
            out_list.append(out_path + "/" + out_filename + ".gz")
            if(verbose):
                print("Wrote: " + out_path + "/" + out_filename + ".gz")

        return out_list

    @classmethod
    def parse_files(cls, file_paths, phred=None, headers2count=10, min_match=2,
                    force_neighbour=False):
        """
        """
        re_win_newline = re.compile(r"\r\n")
        re_mac_newline = re.compile(r"\r")

        re_fastq_header = re.compile(r"(@.+)")

        re_sra = re.compile(r"^(@SRR\d+\.\d+)")
        re_ena = re.compile(r"^(@ERR\d+\.\d+)")

        re_pair_no = re.compile(r"1|2")

        paired = {}
        single = {}
        old_read_headers = {}
        prev_read_headers = {}
        old_org_headers = {}
        prev_org_headers = {}

        for path in file_paths:
            head_count = 0
            is_fastq = False
            file_headers = []

            if(cls.is_gzipped(path)):
                fh = gzip.open(path, "rt", encoding="utf-8")
            else:
                fh = open(path, "r", encoding="utf-8")

            org_headers = {}

            for line in fh:
                line = re_win_newline.sub("\n", line)
                line = re_mac_newline.sub("\n", line)
                line = line.rstrip()

                line_1s_letter = line[0]

                # FASTA format
                if(line_1s_letter == ">"):
                    pass
                # FASTQ format
                elif(line_1s_letter == "@"):
                    # match_fastq_header = re_fastq_header.search(line)
                    # fastq_header = match_fastq_header.group(1)
                    match_sra = re_sra.search(line)
                    match_ena = re_ena.search(line)

                    is_fastq = True
                    head_count += 1

                    # If data is obtained from SRA
                    if(match_sra):
                        header = match_sra.group(1)
                        org_headers[header] = line
                    # If data is obtained from ENA
                    elif(match_ena):
                        header = match_ena.group(1)
                        org_headers[header] = line
                    else:
                        # Masking 1s and 2s so that pairs will match
                        header = re_pair_no.sub("x", line)
                        org_headers[header] = line

                    file_headers.append(header)
                    if(head_count == headers2count):
                        break

            fh.close()

            if(is_fastq):
                if(not phred):
                    # TODO: Implement find phred function
                    pass

                matches = 0
                read_file1 = ""
                read_file2 = ""
                # Check for mates in "neighbors"
                for header in file_headers:
                    if(header in prev_read_headers):
                        if(not match_sra):
                            pair_no = cls.detect_pair_no(
                                org_headers[header], prev_org_headers[header])
                        else:
                            # Correct pair numbering cannot be obtained
                            # from SRA headers.
                            # Attempt to get pair number from filenames
                            filename1 = cls.get_read_filename(path)
                            filename2 = cls.get_read_filename(
                                prev_read_headers[header])
                            pair_no = cls.detect_pair_no(filename1, filename2)

                        if(pair_no is not None):
                            matches += 1
                            if(pair_no == 2):
                                read_file1 = prev_read_headers[header]
                            else:
                                read_file1 = path
                                read_file2 = prev_read_headers[header]

                if(matches >= min_match):
                    if(read_file2):
                        paired[read_file1] = read_file2
                        del single[read_file2]
                    else:
                        paired[read_file1] = path
                elif(not force_neighbour):
                    matches = 0
                    read_file1 = ""
                    read_file2 = ""

                    for header in file_headers:
                        if(header in old_read_headers):
                            if(not match_sra):
                                pair_no = cls.detect_pair_no(
                                    org_headers[header],
                                    old_org_headers[header]
                                )
                            else:
                                # Correct pair numbering cannot be obtained
                                # from SRA headers.
                                # Attempt to get pair number from filenames
                                filename1 = cls.get_read_filename(path)
                                filename2 = cls.get_read_filename(
                                    old_read_headers[header])

                                pair_no = cls.detect_pair_no(filename1,
                                                             filename2)

                            if(pair_no is not None):
                                matches += 1
                                if(pair_no == 2):
                                    read_file1 = old_read_headers[header]
                                else:
                                    read_file1 = path
                                    read_file2 = old_read_headers[header]

                            # Check if there are more than one match
                            if(read_file1 and read_file1 in paired):
                                print("Header matches multiple read files.\n\
                                       Header: " + header + "\n\
                                       File 1: " + read_file1 + "\n\
                                       File 2: " + paired[read_file1] + "\n\
                                       File 3: " + path + "\n\
                                       DONE!")
                                quit(1)

                    if(matches >= min_match):
                        if(read_file2):
                            paired[read_file1] = read_file2
                            del single[read_file2]
                        else:
                            paired[read_file1] = path
                    else:
                        single[path] = 1

                else:
                    single[path] = 1

                # Moves neighbor headers to old headers
                for header in prev_read_headers.keys():
                    old_read_headers[header] = prev_read_headers[header]
                    old_org_headers[header] = prev_org_headers[header]

                # Resets neighbors
                prev_read_headers = {}
                prev_org_headers = {}
                for header in file_headers:
                    prev_read_headers[header] = path
                    prev_org_headers[header] = org_headers[header]

        output_seq_files = []

        for path in file_paths:
            if(path in paired):
                seq_file = SeqFile(path, pe_file_reverse=paired[path],
                                   phred_format=phred)
                output_seq_files.append(seq_file)
            elif(path in single):
                seq_file = SeqFile(path, phred_format=phred)
                print("Created seqfile: " + seq_file.filename)
                output_seq_files.append(seq_file)

        return output_seq_files

    @staticmethod
    def detect_pair_no(header1, header2):
        """ Given two fastq headers, will output if header1 is either 1 or 2.
            If the headers are not does not match, method will return None
        """
        head_diff = ndiff(header1, header2)
        mismatches = 0
        pair_no = None

        for s in head_diff:
            if(s[0] == "-"):
                if(s[2] == "2"):
                    pair_no = 2
                    mismatches += 1
                elif(s[2] == "1"):
                    pair_no = 1
                    mismatches += 1
                else:
                    mismatches += 1

        if(mismatches < 2):
            return pair_no
        else:
            return None

    @staticmethod
    def load_seq_files(file_paths):
        """ Given a list of file paths, returns a list of SeqFile objects.
        """
        file_paths_str = " ".join(file_paths)

        # Running parse_input
        # TODO: Should be rewritten as proper python class.
        parse_input_cmd = ("perl parse_input.pl " + file_paths_str
                           + " > parse_input.output.txt")
        print("PARSE CMD: " + parse_input_cmd)
        try:
            subprocess.check_call([parse_input_cmd], shell=True)
        except subprocess.CalledProcessError:
            print("ERROR: parse input call failed")
            print("CMD that failed: " + parse_input_cmd)
            quit(1)

        file_list = []

        with open("parse_input.output.txt", "r", encoding="utf-8") as input_fh:
            for line in input_fh:
                entries = line.split("\t")
                if(entries[0] == "paired"):
                    print("PAIRED")
                    file_list.append(
                        SeqFile(seqfile=entries[1].strip(),
                                pe_file_reverse=entries[3].strip(),
                                phred_format=entries[2].strip()))
                elif(entries[0] == "single"):
                    print("SINGLE")
                    file_list.append(SeqFile(seqfile=entries[1].strip(),
                                             phred_format=entries[2].strip()))
                elif(entries[0] == "assembled"):
                    print("ASSEMBLED")
                    file_list.append(SeqFile(seqfile=entries[1].strip()))

        return file_list

class KMA():

    def __init__(self, seqfile, tmp_dir, db, loci_list, kma_path, fasta = False):
        """ Constructor map reads from seqfile object using kma.
        """
        # Create kma command line list
        if fasta == False:
            filename = seqfile.filename

            # Add reverse reads if paired-end data
            if(seqfile.pe_file_reverse):
                kma_call_list = [kma_path, "-ipe"]
                kma_call_list.append(seqfile.path)
                kma_call_list.append(seqfile.pe_file_reverse)
                filename = filename.split("/")[-1].split(".")[0]
                # Erase PE endings
                filename = filename.replace("_1", "")
                filename = filename.replace("_2", "")
                filename = filename.replace("_R1", "")
                filename = filename.replace("_R2", "")
            else:
                kma_call_list = [kma_path, "-i"]
                kma_call_list.append(seqfile.path)
        
        # this if for fasta files...
        else:
            kma_call_list = [kma_path, "-i"]
            filename = seqfile.split("/")[-1].split(".")[0]
            kma_call_list.append(seqfile)
        
        result_file_tmp = tmp_dir + "/kma_" + filename
        self.filename = filename
        self.result_file = result_file_tmp + ".res"
        self.fasta_file = result_file_tmp + ".fsa"
        self.seqfile = seqfile
        self.percentage_called_alleles = None
        self.called_alleles = None

        tmp_dir = tmp_dir +"/"
        kma_call_list += [
            "-o", result_file_tmp,
            "-tmp", tmp_dir,
            "-t_db", db,
            "-mem_mode", "-cge", "-boot", "-1t1", "-and"]

        # Call kma externally
        print("# KMA call: " + " ".join(kma_call_list))
        process = subprocess.Popen(kma_call_list, shell=False, stdout=subprocess.PIPE) #, stderr=subprocess.PIPE)
        out, err = process.communicate()
        print("KMA call ended")
    
    def _extract_seq_from_fsa(self, locus):
        """Extracts sequence to specifed locus entry from kma fasta file."""
        with open(self.fasta_file, "r") as fsa_file:
            seq = ""
            line = fsa_file.readline()
            for line in fsa_file:
                if line.startswith(">" + locus):
                    line=fsa_file.readline()
                    while line != "" and line[0] != ">":
                        seq += line
                        line=fsa_file.readline()               
        return seq
    
    def _md5_sum(self, md5_alleles, best_alleles):
        # Get fasta sequence from kma.fsa file
        with open(self.fasta_file, "r") as fsa_file:
            for line in fsa_file:
                line = line.rstrip()
                if line.startswith(">"):
                    entry = line[1:]
                # Save sequence if entry in the md5 dict and not in best alleles
                elif entry in md5_alleles:
                    if md5_alleles[entry]["locus"] not in best_alleles:
                        md5_alleles[entry]["seq"] += line

        # Get md5 for all "clean" sequences
        for entry, d in md5_alleles.items():
            if d["seq"] != "":
                # Check that only ATCG are in the sequence and all bases are uppercase
                # (This assumes that all 4 bases has to be present in the sequence)
                # This has been modified to be lowercase, since that is the format of the kma.fsa file - Edward (G37543428) 02/02/24
                if set(d["seq"]) == {"A", "T", "C", "G"}:
                    md5_alleles[entry]["md5"] = hashlib.md5(d["seq"].encode("utf-8")).hexdigest()

        md5_final = {}
        for entry in md5_alleles:
            locus = md5_alleles[entry]["locus"]
            ident = md5_alleles[entry]["identity"]
            if "md5" in md5_alleles[entry]:
                if locus not in md5_final:
                    md5_final[locus] = md5_alleles[entry]
                else:
                    if ident > md5_final[locus]["identity"]:
                        md5_final[locus] = md5_alleles[entry]
        return md5_final

    def best_allel_hits(self):
        """
        Extracts perfect matching allel hits from kma results file and returns
        a list(string) found allel profile ordered based on the gene list.
        """

        best_alleles = {}
        md5_alleles = {}

        # Create dict of locus and allel with the highest quality score
        with open(self.result_file, "r") as result_file:
            header = result_file.readline()
            header = header.strip().split("\t")

            depth_index          = header.index("Depth")
            query_id_index       = header.index("Query_Identity")
            template_cover_index = header.index("Template_Coverage")
            q_val_index          = header.index("q_value")

            loci_allel = re.compile(r"(\S+)_(\d+)")
            i = 0
            found_loci = []
            for line in result_file:
                i += 1
                data = line.rstrip().split("\t")
                loci_allel_object = loci_allel.search(line)
                locus = loci_allel_object.group(1)
                allel = loci_allel_object.group(2)

                locus_allele_entry = data[0]
                q_score = float(data[q_val_index])
                template_cover = float(data[template_cover_index])
                query_id = float(data[query_id_index])
                depth = float(data[depth_index])

                found_loci.append(locus)
                if query_id == 100 and template_cover == 100:
                    # Check if allel has a higher q_score than the saved allel
                    if locus in best_alleles:
                        if best_alleles[locus][3] < depth:
                            best_alleles[locus] = [allel, q_score, template_cover, depth]
                    else:
                        best_alleles[locus] = [allel, q_score, template_cover, depth]

                # Find potential new alleles to get md5 checksum
                elif query_id != 100 and template_cover == 100:
                    md5_alleles[locus_allele_entry] = {"locus":locus, "allele":allel,
                                                           "identity":query_id,
                                                           "depth":depth, "seq":""}

        md5_dict = self._md5_sum(md5_alleles, best_alleles)

        # Get called alleles
        allele_profile = [self.filename]
        not_called_alleles = 0
        hyp_file = os.path.join(outdir, "Hypothetical_new_alleles.fsa")
        with open(hyp_file, "w") as fh:
            for locus in loci_list:
                locus = locus.strip()
                if locus in best_alleles:
                     allele_profile.append(str(best_alleles[locus][0]))
                elif locus in md5_dict:
                    description = "hyp.allele" + locus
                    allele_profile.append(description)
                    # Hypothetical new allele
                    fh.write(">" + locus + " Hypothetical new allele\n")
                    seq = self._extract_seq_from_fsa(locus)
                    fh.write(seq)
                else:
                     allele_profile.append("-")
                     not_called_alleles += 1
        
        self.called_alleles = len(loci_list) - not_called_alleles
        try:
            self.percentage_called_alleles = round((float(self.called_alleles) / len(loci_list)) * 100.0, 2)
        except ZeroDivisionError:
            self.percentage_called_alleles = 0
        #output også hyp_allele_fasta, gerne i output folderen!
        return ["\t".join(allele_profile)]


def st_typing(loci_allel_dict, inp, summary_cont, pickle_path):
    """
    Takes the path to a pickled dictionary, the inp list of the allel
    number that each loci has been assigned, and an output file string
    where the found st type and similaity is written into it.
    """

    # Find best ST type for all allel profiles
    st_output = []

    # First line contains matrix column headers, which are the specific loci
    loci = inp[0].strip().split("\t")

    for sample_str in inp[1:]:
        sample = sample_str.strip().split("\t")
        sample_name = sample[0]
        st_hits = []

        # Create ST-type file if pickle containing profile list exist
        if os.path.isfile(pickle_path):

            for i in range(1, len(sample)):
                allel = sample[i]
                locus = loci[i]
                # Loci/Allel combination may not be found in the large profile file
                st_hits += loci_allel_dict[locus].get(allel, ["None"])

            # Find most frequent st_type in st_hits
            score = {}
            max_count = 0
            best_hit = ""
            for hit in st_hits:
                if hit in score:
                    score[hit] += 1
                    if max_count < score[hit]:
                        max_count = score[hit]
                        best_hit = hit
                elif(hit != "None"):
                    score[hit] = 1

            # Prepare output string
            similarity = str(round(max_count/(len(loci) - 1)*100, 2))
        else:
            best_hit = "-"
            max_count = "-"
            similarity = "-"

        summary_cont[sample_name]["cgST"] = best_hit
        summary_cont[sample_name]["allele_matches"] = max_count
        summary_cont[sample_name]["perc_allele_matches"] = similarity
    return summary_cont

def file_format(input_files):
    """
    Takes all input files and checks their first character to assess
    the file format. 3 lists are return 1 list containing all fasta files
    1 containing all fastq files and 1 containing all invalid files
    """
    fasta_files = []
    fastq_files = []
    invalid_files = []
    for infile in input_files:
        # Check valid input path
        if not os.path.exists(infile):
            print("Input Error: Input file does not exist!\n")
            sys.exit(1)    
        # Open input file and get the first character
        try:
            f =  gzip.open(infile, "rb")
            fst_char = f.read(1)
        except OSError:
            f = open(infile, "rb")
            fst_char = f.read(1)
        f.close()
        # Return file format based in first char
        if fst_char == b"@":
            fastq_files.append(infile)
        elif fst_char == b">":
            fasta_files.append(infile)
        else:
            invalid_files.append(infile)
    return (fasta_files, fastq_files, invalid_files)


def runProd(assembly_path, prod_path, tmp_dir, outdir):
    """
    Executes Prodigal from the input file and return file of the coding regions 
    in nucleotides.
    assembly_path contains the contigs/assembled genome in fasta format.
    prod_path is the path prodigal specified with -p.
    """
    if SeqFile.is_gzipped(assembly_path):
        # Unzip file before running Prodigal
        cmd = "gzip -cd {}".format(assembly_path)
        assembly_path = os.path.join(tmp_dir, os.path.basename(assembly_path).strip(".gz"))
        with open(assembly_path, "w+") as f:
            subprocess.Popen(cmd, shell=True, stdout=f)

    # Process assembly input and define CDS filename
    filename = os.path.basename(assembly_path).split(".")[0] 
    CDS_file = os.path.join(outdir, filename + ".cds")
        
    # Execute prodigal and write coding regions to file
    cmd = "{} -c -q -i {} -d {}".format(prod_path,assembly_path,CDS_file)
    print("# Executing Prodigal on " + assembly_path)
    print("#")
    print("# Prodigal call: " + cmd)
    print("#")
    proc = subprocess.Popen(cmd, shell=True, stdout=subprocess.DEVNULL).wait() 
    print("Prodigal call ended")
    return CDS_file   
        

if __name__ == "__main__":
    
    ##########################################################################
    # PARSE COMMAND LINE OPTIONS                                             #
    ##########################################################################
    
    parser = ArgumentParser()
    
    parser.add_argument("-i", "--inputfile",
                              help="FASTA or FASTQ files to type.",
                              default=None)
    parser.add_argument("-s", "--species",
                        help="Species. Must match the name of a species directory in the database",
                        default=None)
    # Optional arguments
    parser.add_argument("-db", "--databases",
                        help="Path to the directory containing the databases and gene\
                              lists for each species.",
                        default="cgmlstfinder_db")
    parser.add_argument("-o", "--outdir",
                        help="Output directory.",
                        default="")
    parser.add_argument("-t", "--tmp_dir",
                        help="Temporary directory for storage of the results\
                              from the external software.")
    parser.add_argument("-p", "--prodigal_path",
                              help="Path to Prodigal if input is in FASTA format",
                              default="prodigal")
    parser.add_argument("-k", "--kmapath",
                        help="Path to executable kma program.",
                        default="kma")     
    parser.add_argument("-n", "--nj_path",
                        help="Path to executable neighbor joining program.")                        
    parser.add_argument("-mem", "--shared_memory",
                        action="store_true",
                        help="Use shared memory to load database.")
    parser.add_argument("-q", "--quiet", action="store_true")
    parser.add_argument("--version", action="version", version=version_numb)
    args = parser.parse_args()
    
    
    
    ##########################################################################
    # MAIN                                                                   #   
    ##########################################################################
    
    
    ##### Validate arguments

    # Check if valid output directory is provided
    if args.outdir:
        outdir = os.path.abspath(args.outdir)
        if not os.path.exists(args.outdir):
            print("Input Error: Output dirctory does not exists!\n")
            sys.exit(1)
    else:
       outdir = os.getcwd()
    
    # Check if valid temporary directory is provided
    if args.tmp_dir:
        tmp_dir = os.path.abspath(args.tmp_dir)
        if not os.path.exists(tmp_dir):
            print("Input Error: temperary directory does not exist\n")
            sys.exit(1)
    else:
        tmp_dir = outdir
        
    # Check if valid kma path is provided
    if shutil.which(args.kmapath) is None:
        print("No valid path to a kma program was provided. Use the -k flag to provide the path.")
        sys.exit(1)
    kma_path = args.kmapath
    
    # Check if valid database is provided
    if args.databases:
        db_path = os.path.abspath(args.databases)
        if not os.path.exists(args.databases):
            print("Input Error: The specified database directory does not "
                 "exist!\n")
            sys.exit(1)  
        
    # Specify species scheme database
    if args.species is None:
        print("Input Error: No species name was provided!\n")
        sys.exit(1)
    else:
        species = args.species
    # Save paths including species
    db_dir = db_path + "/" + species
    db_species_scheme = db_dir + "/" + species
    
    
    ## Loci file loading
    
    # Check existence of the loci list file
    loci_list_file = "%s/loci_list.txt" % (db_dir)
    if(not os.path.isfile(loci_list_file)):
        print("Loci list not found at expected location: %s"%(loci_list_file))
        sys.exit(1)
    
    # Load loci file into list
    with open(loci_list_file, "r") as ll:
        loci_list = [locus.strip() for locus in ll.readlines()]

    # Write loci in header of output file
    allel_output = ["Genome\t%s" %("\t".join(loci_list))]
    summary_cont = {}

    # Load ST-dict pickle
    pickle_path = "%s/profile.p" % (db_dir)
    if os.path.isfile(pickle_path):
        try:
            loci_allel_dict = pickle.load(open(pickle_path, "rb"))
        except IOError:
            print("Error, pickle '{}' could not be loaded\n".format(pickle_path))
            sys.exit(1)
    else:
        loci_allel_dict = {}
    
    # Load and check input file(s)
    if args.inputfile is None:
        print("Input Error: No inputfile was provided!\n")
        sys.exit(1)
    inputfile_lst = args.inputfile.split(",")
    for file in inputfile_lst:
        if not os.path.exists(file):
            print("Input Error: Input file not found at expected location: %s"%(file))
            sys.exit(1)
    # Check file format of input files (fasta or fastq, gz or not gz)
    (fasta_files, fastq_files, invalid_files) = file_format(inputfile_lst)


    ##### Process data
    
   
    # Load KMA database into shared memory
    if args.shared_memory:
        cmd = "{}/kma_shm -t_db {}".format(os.path.dirname(kma_path),db_species_scheme)
        proc = subprocess.Popen(shlex.split(cmd), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, err = proc.communicate()
        error_code = proc.returncode
        if error_code != 0:
            print("Shared memory could not be used.\nErr: {}".format(err))
    
    if len(fastq_files) == 0 and len(fasta_files) == 0:
        print("Input file must be fastq or fasta format.\n")
        sys.exit(1)
        
    # If input is raw reads
    if len(fastq_files) >= 1:
    
        # Load fastq files and pair them if necessary
        fastq_files = SeqFile.parse_files(fastq_files, phred=33)  
        
        # Find alleles from fastq file using KMA
        for seqfile in fastq_files:
            
            # Run KMA
            seq_kma = KMA(seqfile, tmp_dir, db_species_scheme, loci_list, kma_path, fasta = False)

            # Get called allelel
            allel_output += seq_kma.best_allel_hits()

            # Get summery file content
            summary_cont[seq_kma.filename] = {"called_alleles":str(seq_kma.called_alleles),
                                              "perc_called_alleles":str(seq_kma.percentage_called_alleles)}

    # If input is an assembly
    if len(fasta_files) >= 1:
        
        # Check if valid prodigal path is provided
        if args.prodigal_path != "prodigal":
            prod_path = os.path.abspath(args.prodigal_path)
            if not os.path.exists(prod_path):
                print("Input Error: prodigal path does not exist: " + prod_path + "\n")
                sys.exit(1)
        else:
            prod_path = args.prodigal_path
        
        # Run KMA on coding regions
        for seqfile in fasta_files:          
            # Run prodigal to identify coding regions
            CDS_file = runProd(seqfile, prod_path, tmp_dir, outdir)
            
            # Run KMA to find alleles from fasta file
            seq_kma = KMA(CDS_file, tmp_dir, db_species_scheme, loci_list, kma_path, fasta = True)
            cmd = "rm {}".format(CDS_file)
            subprocess.Popen(cmd, shell=True, stdout=subprocess.DEVNULL)
            
            # Get called allelel
            allel_output += seq_kma.best_allel_hits()

            # Get summery file content
            summary_cont[seq_kma.filename] = {"called_alleles":str(seq_kma.called_alleles),
                                              "perc_called_alleles":str(seq_kma.percentage_called_alleles)}

    # Destroy KMA database from shared memory
    if args.shared_memory:
        cmd = "{}/kma_shm -t_db {} -destroy".format(os.path.dirname(kma_path),db_species_scheme)
        proc = subprocess.Popen(shlex.split(cmd), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, err = proc.communicate()
        error_code = proc.returncode
        if error_code != 0:
            print("Shared memory could not be destroyed.\nErr: {}".format(err))
    
    
    ##### Prepare output
    
    # Write output summary file
    summary_file = os.path.join(outdir, species + "_summary.txt")
    summary_header = "Sample_name\tTotal_number_of_loci\tNumber_of_called_alleles\t%_Called_alleles\tcgST\tAllele_matches_in_cgST\t%_Allele_matches"
    # Create output lines
    summary_cont = st_typing(loci_allel_dict, allel_output, summary_cont, pickle_path)
    
    # Create output string
    output_lines = []
    for filename, d in summary_cont.items():
        output_lines.append("\t".join([filename, str(len(loci_list)),
                                   str(d["called_alleles"]), str(d["perc_called_alleles"]),
                                   str(d["cgST"]), str(d["allele_matches"]), str(d["perc_allele_matches"])]))
    
    # Write ST-type output
    with open(summary_file, "w") as fh:
        fh.write(summary_header + "\n")
        fh.write("\n".join(output_lines) + "\n")
        for line in output_lines:
            print(line)

    # Write allel matrix output
    allele_matrix = os.path.join(outdir, species + "_results.txt")
    with open(allele_matrix, "w") as fh:
        fh.write("\n".join(allel_output) + "\n")

    # Write json file
    service = "cgMLSTFinder"
    data = {service:{}}
    userinput = {"filenames":args.inputfile, "species":args.species}
    run_info = {"date":time.strftime("%d.%m.%Y"),
                "time":time.strftime("%H:%M:%S")}
    
    data[service]["user_input"] = userinput
    data[service]["run_info"] = run_info
    data[service]["results"] = summary_cont

    result_file = os.path.join(outdir, "data.json")
    with open(result_file, "w") as outfile:
        json.dump(data, outfile)

    ##### Extended format - Create tree if neighbor parameter was sat
    if args.nj_path:
        # Check that more than 2 + header samples are included in the analysis
        if len(allel_output) > 3:
            python_path = sys.executable
            tree_script = os.path.join(os.path.dirname(__file__), "make_nj_tree.py")
            cmd = "{} {} -i {} -o {} -n {}".format(python_path, tree_script, allele_matrix, outdir, args.nj_path)
            proc = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            out, err = proc.communicate()
            out = out.decode("utf-8")
            err = err.decode("utf-8")

            if proc.returncode != 0:
                print("No neighbor joining tree was created. The neighbor program responded with this: {}".format(err))
            else:
                # print newick

                tr = Tree("{}/allele_tree.newick".format(outdir))

                print(tr.get_ascii())
