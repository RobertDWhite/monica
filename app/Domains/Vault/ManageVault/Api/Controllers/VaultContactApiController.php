<?php

namespace App\Domains\Vault\ManageVault\Api\Controllers;

use App\Domains\Contact\ManageContact\Services\CreateContact;
use App\Domains\Contact\ManageContact\Services\DestroyContact;
use App\Domains\Contact\ManageContact\Services\UpdateContact;
use App\Http\Controllers\ApiController;
use App\Http\Resources\ContactResource;
use App\Models\Vault;
use Illuminate\Http\Request;

/**
 * @group Contact management
 *
 * @subgroup Contacts
 */
class VaultContactApiController extends ApiController
{
    public function __construct()
    {
        $this->middleware('abilities:read')->only(['index', 'show']);
        $this->middleware('abilities:write')->only(['store', 'update', 'destroy']);

        parent::__construct();
    }

    /**
     * List all contacts.
     *
     * Get all the contacts in the given vault.
     */
    public function index(Request $request, string $vaultId)
    {
        $vault = $request->user()->account->vaults()->findOrFail($vaultId);

        $contacts = $vault->contacts()
            ->paginate($this->getLimitPerPage());

        return ContactResource::collection($contacts);
    }

    /**
     * Create a contact.
     *
     * Creates a contact object inside the given vault.
     */
    public function store(Request $request, string $vaultId)
    {
        $data = [
            'account_id' => $request->user()->account_id,
            'author_id' => $request->user()->id,
            'vault_id' => $vaultId,
            'first_name' => $request->input('first_name'),
            'last_name' => $request->input('last_name'),
            'middle_name' => $request->input('middle_name'),
            'nickname' => $request->input('nickname'),
            'maiden_name' => $request->input('maiden_name'),
            'prefix' => $request->input('prefix'),
            'suffix' => $request->input('suffix'),
            'gender_id' => $request->input('gender_id'),
            'pronoun_id' => $request->input('pronoun_id'),
            'listed' => $request->boolean('listed', true),
        ];

        $contact = (new CreateContact)->execute($data);

        return new ContactResource($contact);
    }

    /**
     * Retrieve a contact.
     *
     * Get a specific contact object.
     */
    public function show(Request $request, string $vaultId, string $contactId)
    {
        $vault = $request->user()->account->vaults()->findOrFail($vaultId);
        $contact = $vault->contacts()->findOrFail($contactId);

        return new ContactResource($contact);
    }

    /**
     * Update a contact.
     *
     * Updates a contact object.
     */
    public function update(Request $request, string $vaultId, string $contactId)
    {
        $vault = $request->user()->account->vaults()->findOrFail($vaultId);
        $vault->contacts()->findOrFail($contactId);

        $data = [
            'account_id' => $request->user()->account_id,
            'author_id' => $request->user()->id,
            'vault_id' => $vaultId,
            'contact_id' => $contactId,
            'first_name' => $request->input('first_name'),
            'last_name' => $request->input('last_name'),
            'middle_name' => $request->input('middle_name'),
            'nickname' => $request->input('nickname'),
            'maiden_name' => $request->input('maiden_name'),
            'prefix' => $request->input('prefix'),
            'suffix' => $request->input('suffix'),
            'gender_id' => $request->input('gender_id'),
            'pronoun_id' => $request->input('pronoun_id'),
        ];

        $contact = (new UpdateContact)->execute($data);

        return new ContactResource($contact);
    }

    /**
     * Delete a contact.
     *
     * Destroys a contact object.
     */
    public function destroy(Request $request, string $vaultId, string $contactId)
    {
        $vault = $request->user()->account->vaults()->findOrFail($vaultId);
        $vault->contacts()->findOrFail($contactId);

        (new DestroyContact)->execute([
            'account_id' => $request->user()->account_id,
            'author_id' => $request->user()->id,
            'vault_id' => $vaultId,
            'contact_id' => $contactId,
        ]);

        return $this->respondObjectDeleted($contactId);
    }
}
