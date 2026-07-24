#!/usr/bin/env pwsh

sf data query --use-tooling-api  --query "SELECT QualifiedApiName, Label FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'MessagingSession' AND QualifiedApiName LIKE '%__c'"