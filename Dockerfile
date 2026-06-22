FROM nvidia/cuda:12.1.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PATH=/usr/local/bin:/usr/bin:/bin:$PATH

LABEL author="muhammad_tayyab" \
      project="methylbert_hcc_cfdna" \
      version="2.0.2_Cloud_Rigorous"

# 1. Unlock OS Repositories
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common curl wget git nano ca-certificates gnupg dirmngr && \
    add-apt-repository -y universe && \
    add-apt-repository -y multiverse && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Install system-level build deps (remove bio tools from apt list; install via conda/bioconda below)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.11 python3.11-dev python3.11-distutils python3.11-venv \
    build-essential cmake zlib1g-dev libbz2-dev liblzma-dev \
    libcurl4-openssl-dev libssl-dev libncurses5-dev libhts-dev \
    perl default-jre-headless pigz parallel \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. Kernel Python Mapping
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 100 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.11 100

# 4. Bootstrap pip (use the system python3.11)
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11 && \
    python3.11 -m pip install --no-cache-dir --upgrade pip setuptools wheel && \
    python3.11 -m pip install --no-cache-dir cython==3.0.11 numpy==2.1.1

# 5. Install heavy bioinformatics tools via conda/bioconda (bismark, methyldackel, etc.)
ENV CONDA_DIR=/opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH

# Install Miniconda, mamba, then bio tools from bioconda/conda-forge
RUN wget -qO /tmp/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash /tmp/miniconda.sh -b -p $CONDA_DIR && \
    rm /tmp/miniconda.sh && \
    $CONDA_DIR/bin/conda config --set always_yes true --set changeps1 false && \
    $CONDA_DIR/bin/conda update -n base -c defaults conda && \
    $CONDA_DIR/bin/conda install -c conda-forge mamba && \
    $CONDA_DIR/bin/mamba install -c conda-forge -c bioconda \
        samtools=1.17 bowtie2=2.5.0 bismark=0.23.1 trim-galore=0.6.7 methyldackel=0.5.1 bedtools=2.30.0 && \
    $CONDA_DIR/bin/conda clean -afy

# 6. Scientific Suite (Python packages)
RUN python3.11 -m pip install --no-cache-dir --no-build-isolation \
    pandas==2.2.2 scipy==1.14.1 scikit-learn==1.5.1 \
    matplotlib==3.9.2 seaborn==0.13.2 pysam==0.22.1 \
    pybedtools==0.10.0 tqdm==4.66.5 pyyaml==6.0.2 jupyterlab==4.2.5

# 7. Deep Learning & HuggingFace Core
RUN python3.11 -m pip install --no-cache-dir torch==2.4.1 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 && \
    python3.11 -m pip install --no-cache-dir transformers==4.44.2 tokenizers==0.19.1 datasets==2.21.0 accelerate==0.34.2 evaluate==0.4.3 huggingface_hub==0.24.6 pyfaidx==0.8.1.1 statsmodels==0.14.2

# 8. Mount Verified MethylBERT Upstream Object
RUN python3.11 -m pip install --no-cache-dir git+https://github.com/CompEpigen/methylbert.git@c85fc76b006c99c8369ec987b74457e5b565a0c8

CMD ["python3"]
