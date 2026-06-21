<?php

namespace App\Domains\Vault\ManageVault\Api\Controllers;

use App\Domains\Contact\ManageRelationships\Services\SetRelationship;
use App\Domains\Contact\ManageRelationships\Services\UnsetRelationship;
use Illuminate\Http\Request;

/**
 * @group Contact management
 *
 * @subgroup Relationships
 */
class ContactRelationshipApiController extends ContactModuleApiController
{
    public function store(Request $request, string $vaultId, string $contactId)
    {
        (new SetRelationship)->execute($this->baseData($request, $vaultId, $contactId) + [
            'relationship_type_id' => $request->input('relationship_type_id'),
            'other_contact_id' => $request->input('other_contact_id'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function destroy(Request $request, string $vaultId, string $contactId)
    {
        (new UnsetRelationship)->execute($this->baseData($request, $vaultId, $contactId) + [
            'relationship_type_id' => $request->input('relationship_type_id'),
            'other_contact_id' => $request->input('other_contact_id'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }
}
