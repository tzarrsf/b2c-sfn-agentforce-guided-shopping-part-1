User u = [
    SELECT Id, Username, Name
    FROM User
    WHERE Username like '%agentforce%'
    LIMIT 1
];

System.debug('User Id: ' + u.Id + ' | Username: ' + u.Username + ' | Name: ' + u.Name);

PermissionSet ps = [
    SELECT Id, Name
    FROM PermissionSet
    WHERE Name = 'B2C_Guided_Shopping_Agent_Permissions'
    LIMIT 1
];

System.debug('Permission Set Id: ' + ps.Id + ' | Name: ' + ps.Name);

Integer existingAssignments = [
    SELECT COUNT()
    FROM PermissionSetAssignment
    WHERE AssigneeId = :u.Id
    AND PermissionSetId = :ps.Id
];

if (existingAssignments == 0) {
    insert new PermissionSetAssignment(
        AssigneeId = u.Id,
        PermissionSetId = ps.Id
    );
}