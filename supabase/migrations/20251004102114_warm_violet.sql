/*
  # Ajouter la colonne montant à la table rapport

  1. Nouvelle colonne
    - `montant` (decimal, not null, default 0) - Montant unifié pour tous les types
    - Positif pour : Terme, Affaire, Recettes exceptionnelles
    - Négatif pour : Dépenses, Ristournes, Sinistres

  2. Migration des données existantes
    - Copier les valeurs de la colonne `prime` vers `montant`
    - Maintenir la compatibilité avec les données existantes

  3. Index
    - Index sur la colonne montant pour optimiser les calculs de totaux
*/

-- Ajouter la colonne montant à la table rapport
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'rapport' AND column_name = 'montant'
  ) THEN
    ALTER TABLE rapport ADD COLUMN montant DECIMAL(10,2) NOT NULL DEFAULT 0;
  END IF;
END $$;

-- Migrer les données existantes : copier prime vers montant
UPDATE rapport 
SET montant = COALESCE(prime, 0)
WHERE montant = 0 OR montant IS NULL;

-- Créer un index sur la colonne montant pour optimiser les calculs
CREATE INDEX IF NOT EXISTS rapport_montant_idx ON rapport (montant);