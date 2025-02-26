﻿using Microsoft.Extensions.DependencyInjection;

namespace Moonglade.CacheAside.InMemory;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddInMemoryCacheAside(this IServiceCollection services)
    {
        services.AddMemoryCache();
        services.AddSingleton<ICacheAside, MemoryCacheAside>();
        return services;
    }
}