# Compound V2 Wallet Scoring

**Author:** Sai Satyam Jena
**Date:** 5th May 2025
**Assignment Context:** Zeru Finance Take-Home Assignment

---

This repository contains the code and documentation for a project aimed at developing a credit scoring system for Compound V2 protocol wallets based on their historical on-chain transaction behavior.

## 1. Problem Statement & Objective

*   **Goal:** Develop a machine learning model (or scoring system) to assign a credit score between 0 and 100 to Compound V2 protocol wallets based solely on historical transaction behavior extracted from raw, provided data.
*   **Interpretation:** Higher scores should indicate reliable/responsible usage patterns on the Compound V2 protocol. Lower scores should reflect potentially risky, bot-like, or exploitative behavior.
*   **Constraints:**
    *   No pre-existing labels, features, or target columns were provided. Criteria for "good" and "bad" behavior had to be defined independently based on protocol understanding and data exploration.
    *   No external datasets or pre-trained models were permitted.
    *   The scoring logic developed must be non-trivial and derived directly from patterns observed within the provided transaction data.

## 2. Data Source & Handling

*   **Source:** Raw transaction-level data provided via a Google Drive link (Compound V2 Raw Dataset).
*   **Format:** The dataset consisted of multiple JSON files (standard JSON, not JSON Lines). Each file contained a dictionary structure with keys such as `deposits`, `withdraws`, `borrows`, `repays`, each mapping to a list of transaction records.
*   **Files Used:** Due to processing constraints and data volume, the three largest files were selected for the analysis:
    *   `compoundV2_transactions_ethereum_chunk_0.json`
    *   `compoundV2_transactions_ethereum_chunk_1.json`
    *   `compoundV2_transactions_ethereum_chunk_2.json`
*   **Local Setup:**
    *   **IMPORTANT:** These specific JSON files are required locally to run the analysis notebook.
    *   They must be placed inside a `Data/` subfolder within the main project directory: `zeru-compound-scoring/Data/`.
    *   The `DATA_DIR` variable within `scoring_notebook.ipynb` must be set to `'Data'`.
    *   These data files are **excluded** from the Git repository via `.gitignore` due to their large size.
*   **Loading:** Standard Pandas JSON loading methods failed due to inconsistent list lengths within files. A custom loading process was implemented in `scoring_notebook.ipynb` (Cell 2) using Python's `json` library to parse files, iterate through known keys (`deposits`, `withdraws`, `borrows`, `repays`), extract individual records, and compile them into a single list.
*   **Flattening:** The primary data transformation involved converting the list of extracted transaction dictionaries into a flat Pandas DataFrame (`df`), where each row represents a single transaction event.
*   **Key Fields Extracted:**
    *   `wallet_address` (from `account.id`, standardized to lowercase)
    *   `timestamp` (Unix epoch seconds, converted to datetime)
    *   `std_tx_type` (Mapped: 'Deposit', 'Withdraw', 'Borrow', 'Repay')
    *   `amount` (Raw token amount)
    *   `amountUSD` (USD value at transaction time)
    *   `asset_symbol`
    *   `tx_hash`
*   **Data Volume:** Approximately 120,000 valid transaction records were processed from the three selected JSON files.
*   **Critical Finding:** No 'Liquidation' events were found within the keys or records of the processed files. This required adapting the risk assessment strategy to use proxies instead of direct liquidation history.

## 3. Environment Setup

Choose one of the following options to set up the required environment:

### Option A (Recommended): VS Code Dev Container

*   Utilizes the configuration files located in the `.devcontainer/` directory (`devcontainer.json`, `Dockerfile`).
*   **Requirements:**
    *   Docker Desktop installed and running.
    *   Visual Studio Code installed.
    *   VS Code "Dev Containers" extension installed.
*   **Setup:**
    1.  Clone this repository.
    2.  Open the cloned repository folder (`zeru-compound-scoring/`) in VS Code.
    3.  When prompted, or by using the command palette (`Ctrl+Shift+P` or `Cmd+Shift+P`), select **"Dev Containers: Reopen in Container"**.
    4.  VS Code will build the Docker image (if not already built) and start the development container. This container has Python and all dependencies from `requirements.txt` pre-installed.
*   **Benefit:** Provides a consistent, isolated, and reproducible environment.

### Option B: Local Python Virtual Environment (venv)

*   **Requirements:**
    *   Python 3.9 or higher installed locally.
    *   `pip` and `venv` available.
*   **Setup:**
    1.  Clone this repository: `git clone <repository-url>`
    2.  Navigate to the project root directory: `cd zeru-compound-scoring`
    3.  Create a virtual environment: `python -m venv venv` (or `python3 ...`)
    4.  Activate the environment:
        *   **macOS/Linux:** `source venv/bin/activate`
        *   **Windows (Git Bash):** `source venv/Scripts/activate`
        *   **Windows (Command Prompt/PowerShell):** `.\venv\Scripts\activate`
    5.  Install dependencies: `pip install -r requirements.txt`
*   **Key Dependencies:** `pandas`, `numpy`, `scikit-learn`, `notebook`.

## 4. Methodology & Implementation (`scoring_notebook.ipynb`)

The entire analysis pipeline is implemented in the `scoring_notebook.ipynb` Jupyter Notebook.

*   **Cell 1: Imports:** Loads necessary libraries (`pandas`, `numpy`, `sklearn`, `json`, etc.).
*   **Cell 2: Data Loading & Initial Flattening:** Implements the custom JSON loading logic for the specified files in the `Data/` directory.
*   **Cell 3: Data Cleaning & Type Conversion:** Cleans data, converts data types (datetime, numeric), standardizes wallet addresses.
*   **Cell 4: Feature Engineering:** Aggregates transaction data by `wallet_address` to create wallet-level summary statistics. Key features include:
    *   `wallet_lifespan_days`
    *   `net_deposit_amountUSD` (proxy for collateral/stake)
    *   `repayment_ratio_usd` (Repays USD / Borrows USD)
    *   `borrow_to_deposit_ratio_usd` (Borrows USD / Net Deposits USD - proxy for leverage)
    *   `unique_assets_interacted`
    *   `transactions_per_day`
    *   `has_borrowed` (binary flag)
*   **Cell 5: Scoring Model (Weighted Feature Sum):**
    *   Applies a weighted sum scoring model based on selected, normalized (MinMax scaled to [0, 1]) features.
    *   **Rationale:** Chosen for interpretability in an unsupervised context.
    *   **Weights Applied:**
        *   `repayment_ratio_usd`: +0.30
        *   `net_deposit_amountUSD`: +0.25
        *   `wallet_lifespan_days`: +0.20
        *   `unique_assets_interacted`: +0.05
        *   `borrow_to_deposit_ratio_usd`: -0.15 (Penalizes high leverage)
        *   `transactions_per_day`: -0.05 (Slightly penalizes very high frequency)
    *   Calculates a raw score and then scales it to the final `final_score` between 0 and 100.
*   **Cell 6: Output Generation:** Sorts wallets by score and saves the results to CSV files (`top_1000_scores.csv`, `all_wallet_scores_and_features.csv`).
*   **Cell 7: Data for Wallet Analysis:** Extracts data for the top/bottom wallets to aid in documentation.




## 5. Key Results & Findings

*   **Score Distribution:** Scores were heavily skewed low (median ~22.8), indicating most wallets in the analyzed dataset did not exhibit strong "ideal" behavior based on the defined criteria (particularly repayment).
*   **Model Differentiation:** The model effectively distinguished between behavioral patterns:
    *   **High Scorers (~80-100):** Long lifespans, perfect repayment ratios, prudent leverage, significant positive net deposits.
    *   **Low Scorers (~0-10):** Short lifespans, zero repayment, high leverage proxies, zero/negative net deposits, often high transaction frequency.
*   **Validation:** The clear contrast between high and low scorers validates that the feature engineering and weighted model successfully capture and quantify the intended behavioral differences.

## 6. Deliverables Produced

*   **Code:** `scoring_notebook.ipynb`
*   **Output Data:**
    *   `top_1000_scores.csv`
    *   `all_wallet_scores_and_features.csv`
*   **Documentation:**
    *   `Methodology.pdf`
    *   `Wallet_Analysis.pdf`
    *   `README.md` (this file)
*   **Configuration:** `.gitignore`, `requirements.txt`, `.devcontainer/` files.

## 7. Limitations & Future Work

### Limitations

*   Limited data scope (3 files processed).
*   Absence of explicit liquidation data in the processed files.
*   Features are aggregated over the wallet's history, missing time-series nuances.
*   Subjectivity in the chosen feature weights.
*   Basic proxy for bot detection (transaction frequency).
*   Ignores external factors (market conditions, other wallet holdings).

### Future Work

*   Incorporate liquidation data if available.
*   Develop time-series features capturing behavior changes.
*   Explore advanced anomaly detection methods (e.g., Isolation Forest).
*   Use clustering (e.g., K-Means) to identify distinct user groups.
*   Perform sensitivity analysis on feature weights.

## 9. How to Run

1.  Ensure you have the raw JSON data files (`compoundV2_transactions_ethereum_chunk_0.json`, `compoundV2_transactions_ethereum_chunk_1.json`, `compoundV2_transactions_ethereum_chunk_2.json`) placed inside the `Data/` directory (create this directory if it doesn't exist).
2.  Set up the environment using either the Dev Container (Recommended) or a local Python `venv` as described in Section 3.
3.  Activate the environment if using `venv`.
4.  Launch Jupyter Notebook or Jupyter Lab: `jupyter notebook` or `jupyter lab`
5.  Open and run the cells sequentially in `scoring_notebook.ipynb`.
6.  The output CSV files (`top_1000_scores.csv` and `all_wallet_scores_and_features.csv`) will be generated in the project's root directory.

## 10. Code Structure
```plaintext
compound-v2-wallet-scoring/
│
├── .devcontainer/            # VS Code Dev Container configuration
│   ├── devcontainer.json
│   └── Dockerfile            # Dockerfile for the container environment
│
├── Data/                     # FOLDER REQUIRED LOCALLY: Place raw JSON data files here
│   └── (compoundV2_*.json files go here - Not tracked by Git)
│
├── .gitignore                # Specifies intentionally untracked files (Data/, envs, etc.)
├── requirements.txt          # Python dependencies for setup
│
├── scoring_notebook.ipynb    # Jupyter notebook: End-to-end analysis & scoring code
│
├── top_1000_scores.csv       # DELIVERABLE: Scores for the top 1000 wallets
├── all_wallet_scores_and_features.csv # OUTPUT: All features & scores for all analyzed wallets
│
├── Methodology.pdf           # DELIVERABLE: Detailed methodology document
├── Wallet_Analysis.pdf       # DELIVERABLE: Analysis of top/bottom scoring wallets
│
└── README.md                 # This file (Project overview, setup, methodology summary)
