<?php
/**
 * Database Configuration
 * Handles database connection for the Hospital Management System
 */

function getDatabaseConnection() {
    // Database configuration
    $db_host = getenv('DB_HOST') ?: 'localhost';
    $db_name = getenv('DB_NAME') ?: 'hospital_db';
    $db_user = getenv('DB_USER') ?: 'hospital_user';
    $db_pass = getenv('DB_PASS') ?: 'HospitalPass123!';
    
    try {
        $dsn = "mysql:host=$db_host;dbname=$db_name;charset=utf8mb4";
        $options = [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ];
        
        $pdo = new PDO($dsn, $db_user, $db_pass, $options);
        return $pdo;
    } catch (PDOException $e) {
        throw new Exception("Database connection failed: " . $e->getMessage());
    }
}

?>

