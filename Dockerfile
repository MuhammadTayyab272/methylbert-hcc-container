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
    add-apt-repository -y ppa:deadsnakes/ppa

# 2. Compile Core Genomics Infrastructure
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.11 python3.11-dev python3.11-distutils python3.11-venv \
    build-essential cmake zlib1g-dev libbz2-dev liblzma-dev \
    libcurl4-openssl-dev libssl-dev libncurses5-dev libhts-dev \
    perl default-jre-headless pigz parallel \
    samtools bismark bowtie2 trim-galore methyldackel bedtools && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. Kernel Python Mapping
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 100 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.11 100

# 4. Bootstrap Python Packaging Stack
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11 && \
    python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel && \
    python3 -m pip install --no-cache-dir cython==3.0.11 numpy==2.1.1

# 5. Scientific Suite (Build Isolation Disabled)
RUN python3 -m pip install --no-cache-dir --no-build-isolation \
    pandas==2.2.2 scipy==1.14.1 scikit-learn==1.5.1 \
    matplotlib==3.9.2 seaborn==0.13.2 pysam==0.22.1 \
    pybedtools==0.10.0 tqdm==4.66.5 pyyaml==6.0.2 jupyterlab==4.2.5

# 6. Deep Learning & HuggingFace Core
RUN python3 -m pip install --no-cache-dir torch==2.4.1 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 && \
    python3 -m pip install --no-cache-dir transformers==4.44.2 tokenizers==0.19.1 datasets==2.21.0 accelerate==0.34.2 evaluate==0.4.3 huggingface_hub==0.24.6 pyfaidx==0.8.1.1 statsmodels==0.14.2 umap-learn==0.5.6 xgboost==2.1.1 pytorch-lightning==2.4.0

# 7. Mount Verified MethylBERT Upstream Object
RUN python3 -m pip install --no-cache-dir git+https://github.com/CompEpigen/methylbert.git@c85fc76b006c99c8369ec987b74457e5b565a0c8

CMD ["python3"]
