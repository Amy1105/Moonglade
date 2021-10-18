﻿using MediatR;
using Moonglade.Data;
using Moonglade.Data.Entities;
using Moonglade.Data.Infrastructure;
using Moonglade.Utils;

namespace Moonglade.Auth;

public class CreateAccountCommand : IRequest<Guid>
{
    public CreateAccountCommand(string username, string clearPassword)
    {
        Username = username;
        ClearPassword = clearPassword;
    }

    public string Username { get; set; }
    public string ClearPassword { get; set; }
}

public class CreateAccountCommandHandler : IRequestHandler<CreateAccountCommand, Guid>
{
    private readonly IRepository<LocalAccountEntity> _accountRepo;
    private readonly IBlogAudit _audit;

    public CreateAccountCommandHandler(
        IRepository<LocalAccountEntity> accountRepo, IBlogAudit audit)
    {
        _accountRepo = accountRepo;
        _audit = audit;
    }

    public async Task<Guid> Handle(CreateAccountCommand request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Username))
        {
            throw new ArgumentNullException(nameof(request.Username), "value must not be empty.");
        }

        if (string.IsNullOrWhiteSpace(request.ClearPassword))
        {
            throw new ArgumentNullException(nameof(request.ClearPassword), "value must not be empty.");
        }

        var uid = Guid.NewGuid();
        var account = new LocalAccountEntity
        {
            Id = uid,
            CreateTimeUtc = DateTime.UtcNow,
            Username = request.Username.ToLower().Trim(),
            PasswordHash = Helper.HashPassword(request.ClearPassword.Trim())
        };

        await _accountRepo.AddAsync(account);
        await _audit.AddEntry(BlogEventType.Settings, BlogEventId.SettingsAccountCreated, $"Account '{account.Id}' created.");

        return uid;
    }
}