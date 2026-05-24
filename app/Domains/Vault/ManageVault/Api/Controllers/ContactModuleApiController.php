<?php

namespace App\Domains\Vault\ManageVault\Api\Controllers;

use App\Http\Controllers\ApiController;
use App\Http\Resources\ContactResource;
use App\Models\Contact;
use Illuminate\Http\Request;

/**
 * Base controller for contact-module endpoints (notes, tasks, calls, etc.).
 *
 * Every module mutation returns the fully hydrated contact so the mobile
 * client can replace its cached contact in a single round-trip.
 */
abstract class ContactModuleApiController extends ApiController
{
    public function __construct()
    {
        $this->middleware('abilities:read')->only(['index']);
        $this->middleware('abilities:write')->except(['index']);

        parent::__construct();
    }

    /**
     * Resolve a contact the caller is allowed to touch, or 404.
     */
    protected function findContact(Request $request, string $vaultId, string $contactId): Contact
    {
        $vault = $request->user()->account->vaults()->findOrFail($vaultId);

        return $vault->contacts()->findOrFail($contactId);
    }

    /**
     * The account/author/vault/contact keys every module Service requires.
     */
    protected function baseData(Request $request, string $vaultId, string $contactId): array
    {
        return [
            'account_id' => $request->user()->account_id,
            'author_id' => $request->user()->id,
            'vault_id' => $vaultId,
            'contact_id' => $contactId,
        ];
    }

    /**
     * Return the contact with every module relation loaded.
     */
    protected function freshContact(Request $request, string $vaultId, string $contactId): ContactResource
    {
        $vault = $request->user()->account->vaults()->findOrFail($vaultId);
        $contact = $vault->contacts()
            ->with(ContactResource::eagerLoadRelations())
            ->findOrFail($contactId);

        return new ContactResource($contact);
    }
}
