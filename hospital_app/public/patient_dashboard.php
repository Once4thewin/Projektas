<?php
session_start();
require_once __DIR__ . '/../config/database.php';

if (!isset($_SESSION['user_id']) || $_SESSION['user_type'] !== 'patient') {
    header('Location: login.php');
    exit;
}

$pdo = getDatabaseConnection();
$patient_id = null;

// Get patient info
$stmt = $pdo->prepare("SELECT p.* FROM patients p WHERE p.user_id = ?");
$stmt->execute([$_SESSION['user_id']]);
$patient = $stmt->fetch();
$patient_id = $patient['id'];

// Get appointments
$stmt = $pdo->prepare("
    SELECT a.*, d.first_name as doctor_first_name, d.last_name as doctor_last_name, d.specialization
    FROM appointments a
    JOIN doctors d ON a.doctor_id = d.id
    WHERE a.patient_id = ?
    ORDER BY a.appointment_date DESC
");
$stmt->execute([$patient_id]);
$appointments = $stmt->fetchAll();

// Get medical records
$stmt = $pdo->prepare("
    SELECT mr.*, d.first_name as doctor_first_name, d.last_name as doctor_last_name
    FROM medical_records mr
    JOIN doctors d ON mr.doctor_id = d.id
    WHERE mr.patient_id = ?
    ORDER BY mr.visit_date DESC
");
$stmt->execute([$patient_id]);
$records = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html>
<head>
    <title>Patient Dashboard - Hospital Management System</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="header">
        <h1>Patient Dashboard</h1>
        <p>Welcome, <?= htmlspecialchars($patient['first_name'] . ' ' . $patient['last_name']) ?></p>
        <a href="logout.php">Logout</a>
    </div>
    <div class="container">
        <nav>
            <a href="book_appointment.php">Book Appointment</a>
            <a href="search_doctors.php">Search Doctors</a>
        </nav>
        
        <h2>My Appointments</h2>
        <table>
            <tr>
                <th>Date</th>
                <th>Doctor</th>
                <th>Specialization</th>
                <th>Status</th>
                <th>Actions</th>
            </tr>
            <?php foreach ($appointments as $apt): ?>
            <tr>
                <td><?= date('Y-m-d H:i', strtotime($apt['appointment_date'])) ?></td>
                <td>Dr. <?= htmlspecialchars($apt['doctor_first_name'] . ' ' . $apt['doctor_last_name']) ?></td>
                <td><?= htmlspecialchars($apt['specialization']) ?></td>
                <td><?= htmlspecialchars($apt['status']) ?></td>
                <td>
                    <?php if ($apt['status'] === 'scheduled'): ?>
                    <a href="cancel_appointment.php?id=<?= $apt['id'] ?>">Cancel</a>
                    <?php endif; ?>
                </td>
            </tr>
            <?php endforeach; ?>
        </table>
        
        <h2>Medical Records</h2>
        <table>
            <tr>
                <th>Visit Date</th>
                <th>Doctor</th>
                <th>Diagnosis</th>
                <th>Prescription</th>
            </tr>
            <?php foreach ($records as $record): ?>
            <tr>
                <td><?= $record['visit_date'] ? date('Y-m-d', strtotime($record['visit_date'])) : 'N/A' ?></td>
                <td>Dr. <?= htmlspecialchars($record['doctor_first_name'] . ' ' . $record['doctor_last_name']) ?></td>
                <td><?= htmlspecialchars($record['diagnosis'] ?? 'N/A') ?></td>
                <td><?= htmlspecialchars($record['prescription'] ?? 'N/A') ?></td>
            </tr>
            <?php endforeach; ?>
        </table>
    </div>
</body>
</html>

