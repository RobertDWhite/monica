<?php

use App\Domains\Settings\ManageApiTokens\Api\Controllers\OAuthTokenController;
use App\Domains\Settings\ManageUsers\Api\Controllers\UserController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactAddressApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactCallApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactImportantDateApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactInformationApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactNoteApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactReferenceApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactReminderApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactTaskApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\VaultContactApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\VaultController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the bootstrap/app.php file and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

// OAuth token exchange — no Sanctum auth required (validates via OIDC userinfo)
Route::post('auth/token', [OAuthTokenController::class, 'store'])->name('api.auth.token');

Route::middleware('auth:sanctum')->name('api.')->group(function () {
    // users
    Route::get('user', [UserController::class, 'user']);
    Route::apiResource('users', UserController::class)->only(['index', 'show']);

    // vaults
    Route::apiResource('vaults', VaultController::class);

    // contacts
    Route::apiResource('vaults.contacts', VaultContactApiController::class);

    // reference data for contact-module pickers
    Route::get('vaults/{vault}/reference', [ContactReferenceApiController::class, 'index'])
        ->name('vaults.reference.index');

    // contact modules (full CRUD over the existing domain services)
    Route::prefix('vaults/{vault}/contacts/{contact}')->group(function () {
        Route::apiResource('notes', ContactNoteApiController::class)
            ->only(['store', 'update', 'destroy']);

        Route::apiResource('tasks', ContactTaskApiController::class)
            ->only(['store', 'update', 'destroy']);
        Route::post('tasks/{task}/toggle', [ContactTaskApiController::class, 'toggle'])
            ->name('tasks.toggle');

        Route::apiResource('calls', ContactCallApiController::class)
            ->only(['store', 'update', 'destroy']);

        Route::apiResource('reminders', ContactReminderApiController::class)
            ->only(['store', 'update', 'destroy']);

        Route::apiResource('important-dates', ContactImportantDateApiController::class)
            ->only(['store', 'update', 'destroy']);

        Route::apiResource('contact-information', ContactInformationApiController::class)
            ->only(['store', 'update', 'destroy']);

        Route::apiResource('addresses', ContactAddressApiController::class)
            ->only(['store', 'update', 'destroy']);
    });
});
