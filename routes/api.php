<?php

use App\Domains\Settings\ManageApiTokens\Api\Controllers\OAuthTokenController;
use App\Domains\Settings\ManageUsers\Api\Controllers\UserController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactAddressApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactCallApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactGoalApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactAvatarApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactDocumentApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactGroupApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactJobApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactPhotoApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactImportantDateApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactInformationApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactLabelApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactLifeEventApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactLoanApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactMoodTrackingApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactNoteApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactPetApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactQuickFactApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactReferenceApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactRelationshipApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactReligionApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactReminderApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\ContactTaskApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\VaultContactApiController;
use App\Domains\Vault\ManageVault\Api\Controllers\VaultDashboardApiController;
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

    // vault-level dashboards (cross-contact rollups)
    Route::get('vaults/{vault}/dashboard/tasks', [VaultDashboardApiController::class, 'tasks'])->name('vaults.dashboard.tasks');
    Route::get('vaults/{vault}/dashboard/reminders', [VaultDashboardApiController::class, 'reminders'])->name('vaults.dashboard.reminders');
    Route::get('vaults/{vault}/dashboard/posts', [VaultDashboardApiController::class, 'posts'])->name('vaults.dashboard.posts');

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

        // pets
        Route::apiResource('pets', ContactPetApiController::class)
            ->only(['store', 'update', 'destroy']);

        // goals (+ streak toggle)
        Route::apiResource('goals', ContactGoalApiController::class)
            ->only(['store', 'update', 'destroy']);
        Route::post('goals/{goal}/streak', [ContactGoalApiController::class, 'toggleStreak'])
            ->name('goals.streak');

        // quick facts (+ show/hide toggle)
        Route::apiResource('quick-facts', ContactQuickFactApiController::class)
            ->only(['store', 'update', 'destroy']);
        Route::post('quick-facts/toggle', [ContactQuickFactApiController::class, 'toggle'])
            ->name('quick-facts.toggle');

        // mood tracking
        Route::apiResource('mood-tracking', ContactMoodTrackingApiController::class)
            ->only(['store', 'update', 'destroy']);

        // loans / debts (+ settled toggle)
        Route::apiResource('loans', ContactLoanApiController::class)
            ->only(['store', 'update', 'destroy']);
        Route::post('loans/{loan}/toggle', [ContactLoanApiController::class, 'toggle'])
            ->name('loans.toggle');

        // relationships (set / unset between two contacts)
        Route::post('relationships', [ContactRelationshipApiController::class, 'store'])
            ->name('relationships.store');
        Route::delete('relationships', [ContactRelationshipApiController::class, 'destroy'])
            ->name('relationships.destroy');

        // labels (assign existing or create+assign / remove)
        Route::post('labels', [ContactLabelApiController::class, 'store'])
            ->name('labels.store');
        Route::delete('labels/{label}', [ContactLabelApiController::class, 'destroy'])
            ->name('labels.destroy');

        // groups (add existing or create+add / remove)
        Route::post('groups', [ContactGroupApiController::class, 'store'])
            ->name('groups.store');
        Route::delete('groups/{group}', [ContactGroupApiController::class, 'destroy'])
            ->name('groups.destroy');

        // religion
        Route::put('religion', [ContactReligionApiController::class, 'update'])
            ->name('religion.update');

        // life events (each wrapped in a per-event timeline event)
        Route::post('life-events', [ContactLifeEventApiController::class, 'store'])
            ->name('life-events.store');
        Route::put('life-events/{timeline}/{lifeEvent}', [ContactLifeEventApiController::class, 'update'])
            ->name('life-events.update');
        Route::delete('life-events/{timeline}/{lifeEvent}', [ContactLifeEventApiController::class, 'destroy'])
            ->name('life-events.destroy');
        Route::post('life-events/{timeline}/{lifeEvent}/toggle', [ContactLifeEventApiController::class, 'toggle'])
            ->name('life-events.toggle');

        // job information
        Route::put('job', [ContactJobApiController::class, 'update'])->name('job.update');

        // avatar (multipart upload / remove)
        Route::post('avatar', [ContactAvatarApiController::class, 'store'])->name('avatar.store');
        Route::delete('avatar', [ContactAvatarApiController::class, 'destroy'])->name('avatar.destroy');

        // photos (multipart upload / delete)
        Route::post('photos', [ContactPhotoApiController::class, 'store'])->name('photos.store');
        Route::delete('photos/{file}', [ContactPhotoApiController::class, 'destroy'])->name('photos.destroy');

        // documents (multipart upload / delete)
        Route::post('documents', [ContactDocumentApiController::class, 'store'])->name('documents.store');
        Route::delete('documents/{file}', [ContactDocumentApiController::class, 'destroy'])->name('documents.destroy');
    });
});
