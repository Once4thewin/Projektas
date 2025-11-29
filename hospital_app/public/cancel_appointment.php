<?php
session_start();
require_once __DIR__ . '/../config/database.php';

if (!isset($_SESSION['user_id']) || $_SESSION['user_type'] !== 'patient') {
    header('Location: login.php');
    exit;
}

$pdo = getDatabaseConnection();
$appointment_id = $_GET['id'] ?? null;

if ($appointment_id) {
    // Get patient ID
    $stmt = $pdo->prepare("SELECT id FROM patients WHERE user_id = ?");
    $stmt->execute([$_SESSION['user_id']]);
    $patient = $stmt->fetch();
    $patient_id = $patient['id'];
    
    // Cancel appointment
    $stmt = $pdo->prepare("UPDATE appointments SET status = 'cancelled' WHERE id = ? AND patient_id = ?");
    $stmt->execute([$appointment_id, $patient_id]);
}

header('Location: patient_dashboard.php');
exit;
?>

