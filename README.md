# QuickBooks Integration for Salesforce

## Overview
This package provides integration between Salesforce and QuickBooks by adding custom fields to Salesforce standard objects to store QuickBooks data references.

## Features
- Synchronization between Salesforce Accounts and QuickBooks Customers
- Synchronization between Salesforce Contacts and QuickBooks Contacts
- Synchronization between Salesforce Invoice and QuickBooks Invoice
- Tracking of QuickBooks IDs and sync tokens for data integrity

## Technical Details

### Custom Fields
The package includes the following custom fields:

#### Account Object
- `QuickBookId__c`: Stores the QuickBooks ID for the corresponding customer
- `QuickBookSyncToken__c`: Stores the QuickBooks sync token for data synchronization
- `Contact__c`: Reference to a primary contact

#### Contact Object
- `QuickBookId__c`: Stores the QuickBooks ID for the corresponding contact
- `QuickBookSyncToken__c`: Stores the QuickBooks sync token for data synchronization
