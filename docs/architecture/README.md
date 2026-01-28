# Architecture Documentation

This directory contains architecture documentation for the CouponTracker app.

## Contents

- System architecture diagrams
- Component diagrams
- Data flow documentation
- Technical specifications

## Architecture Overview

The app follows a modular MVVM (Model-View-ViewModel) architecture with the following principles:

1. **Separation of Concerns** - Each module has a single responsibility
2. **Dependency Injection** - Dependencies are injected for testability
3. **Protocol-Oriented Design** - Abstractions via protocols for flexibility
4. **Unidirectional Data Flow** - Predictable state management
5. **Structured Logging** - Production-safe logging via os.Logger with domain categories
