import os
import sys
from google.cloud import bigquery

def main():
    # Zorg dat we het juiste service account gebruiken
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = r"C:\Users\Alexb\.gcp\ivy-service-account.json"
    
    # Maak verbinding met BigQuery
    client = bigquery.Client()
    project_id = "ivy-warehouse"
    dataset_id = f"{project_id}.raw_huds"
    
    print(f"Zoeken naar tabellen in {dataset_id}...")
    
    try:
        tables = client.list_tables(dataset_id)
        
        for table_list_item in tables:
            table_id = f"{dataset_id}.{table_list_item.table_id}"
            table = client.get_table(table_id)
            
            # Check of het een externe tabel (Google Sheet) is
            if table.table_type == "EXTERNAL":
                print(f"\nBezig met updaten van {table_id}...")
                
                # Huidige schema ophalen
                current_schema = table.schema
                
                if not current_schema:
                    print(f"Kan huidig schema niet ophalen voor {table_id}. Sla deze over.")
                    continue
                
                # Nieuw schema maken waarbij ELKE kolom een STRING is
                new_schema = []
                for field in current_schema:
                    new_schema.append(bigquery.SchemaField(field.name, "STRING"))
                
                # Pas het schema aan in het tabel-object
                table.schema = new_schema
                
                # Zet autodetect UIT, anders negeert BigQuery ons nieuwe schema
                table.external_data_configuration.autodetect = False
                
                # Stuur de wijzigingen naar BigQuery
                client.update_table(table, ["schema", "externalDataConfiguration"])
                print(f"✅ Succes! Schema voor {table_id} is nu 100% STRING en autodetect staat uit.")
                
    except Exception as e:
        print(f"Er is een fout opgetreden: {e}")

if __name__ == "__main__":
    main()
