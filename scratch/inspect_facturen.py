import os
from google.cloud import bigquery

def main():
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = r"C:\Users\Alexb\.gcp\ivy-service-account.json"
    client = bigquery.Client()
    
    query = """
        SELECT Factuur_nummer, Project, Opdrachtgever 
        FROM `ivy-warehouse.raw_huds.raw_huds_facturen` 
        LIMIT 10
    """
    
    results = client.query(query).result()
    
    print("\n--- INHOUD VAN FACTUREN ---")
    for row in results:
        print(f"Factuur: {row['Factuur_nummer']} | Project: '{row['Project']}' | Opdrachtgever: '{row['Opdrachtgever']}'")

if __name__ == "__main__":
    main()
