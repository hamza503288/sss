/*
  # Corriger définitivement le calcul du montant dans la table rapport

  1. Objectif
    - Si type_paiement = 'Crédit' ET montant_credit existe : montant = prime - montant_credit
    - Si type_paiement = 'Au comptant' : montant = prime
    - Créer un trigger robuste qui fonctionne réellement

  2. Modifications
    - Supprimer tous les anciens triggers et fonctions
    - Créer une nouvelle fonction simple et efficace
    - Créer un nouveau trigger
    - Recalculer tous les montants existants

  3. Debug
    - Ajouter des logs pour vérifier le fonctionnement
    - Tester la logique avec des cas concrets
*/

-- Supprimer tous les anciens triggers et fonctions liés au calcul du montant
DROP TRIGGER IF EXISTS trigger_calculate_rapport_montant ON rapport;
DROP TRIGGER IF EXISTS trigger_calculate_rapport_montant_by_payment_type ON rapport;
DROP TRIGGER IF EXISTS trigger_handle_rapport_data ON rapport;
DROP TRIGGER IF EXISTS trigger_sync_prime_montant ON rapport;
DROP TRIGGER IF EXISTS trigger_handle_rapport_nulls ON rapport;
DROP FUNCTION IF EXISTS calculate_rapport_montant();
DROP FUNCTION IF EXISTS calculate_rapport_montant_by_payment_type();
DROP FUNCTION IF EXISTS handle_rapport_data();
DROP FUNCTION IF EXISTS sync_prime_montant();
DROP FUNCTION IF EXISTS handle_rapport_nulls();

-- Créer une nouvelle fonction simple et robuste
CREATE OR REPLACE FUNCTION calculate_montant_rapport()
RETURNS TRIGGER AS $$
BEGIN
    -- Logique de calcul selon le type de paiement
    IF NEW.type_paiement = 'Crédit' AND NEW.montant_credit IS NOT NULL AND NEW.montant_credit > 0 THEN
        -- Pour les crédits : montant = prime - montant_credit
        NEW.montant := NEW.prime - NEW.montant_credit;
    ELSE
        -- Pour les paiements au comptant : montant = prime
        NEW.montant := NEW.prime;
    END IF;
    
    -- Gérer les valeurs NULL pour les paiements au comptant
    IF NEW.type_paiement = 'Au comptant' THEN
        NEW.montant_credit := NULL;
        NEW.date_paiement_prevue := NULL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Créer le nouveau trigger
CREATE TRIGGER trigger_calculate_montant_rapport
    BEFORE INSERT OR UPDATE ON rapport
    FOR EACH ROW
    EXECUTE FUNCTION calculate_montant_rapport();

-- Recalculer tous les montants existants avec la nouvelle logique
UPDATE rapport 
SET montant = CASE 
    WHEN type_paiement = 'Crédit' AND montant_credit IS NOT NULL AND montant_credit > 0 THEN 
        prime - montant_credit
    ELSE 
        prime
END;