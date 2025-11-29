<?php
/**
 * Hospital Management System - Main Entry Point
 */

session_start();
require_once __DIR__ . '/../config/database.php';

// Check if user is logged in
$logged_in = isset($_SESSION['user_id']);
$user_type = $_SESSION['user_type'] ?? null;
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hospital Management System</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="header">
        <h1>Hospital Management System</h1>
        <?php if ($logged_in): ?>
            <a href="logout.php">Logout</a>
            <?php if ($user_type === 'doctor'): ?>
                <a href="doctor_dashboard.php">Doctor Dashboard</a>
            <?php else: ?>
                <a href="patient_dashboard.php">Patient Dashboard</a>
            <?php endif; ?>
        <?php else: ?>
            <a href="login.php">Login</a>
            <a href="register.php">Register</a>
        <?php endif; ?>
    </div>
    <div class="container">
        <h2>Welcome to the Hospital Management System</h2>
        <p>Manage your appointments, medical records, and connect with healthcare professionals.</p>
        
        <?php
        // Test database connection
        try {
            $pdo = getDatabaseConnection();
            echo "<p class='success'>✓ Database connection successful!</p>";
        } catch (Exception $e) {
            echo "<p class='error'>✗ Database connection failed: " . htmlspecialchars($e->getMessage()) . "</p>";
        }
        ?>
        
        <?php if (!$logged_in): ?>
        <div style="margin-top: 30px;">
            <h3>Get Started</h3>
            <p><a href="register.php">Register as a Patient</a> or <a href="register.php">Register as a Doctor</a></p>
            <p>Already have an account? <a href="login.php">Login here</a></p>
        </div>
        <?php endif; ?>
    </div>
</body>
</html>

