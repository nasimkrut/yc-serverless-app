FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["GuestbookApi/GuestbookApi.csproj", "GuestbookApi/"]
RUN dotnet restore "GuestbookApi/GuestbookApi.csproj"
COPY GuestbookApi/ GuestbookApi/
RUN dotnet publish "GuestbookApi/GuestbookApi.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "GuestbookApi.dll"]
