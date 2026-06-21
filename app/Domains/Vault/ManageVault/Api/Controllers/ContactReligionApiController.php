<?php

namespace App\Domains\Vault\ManageVault\Api\Controllers;

use App\Domains\Contact\ManageReligion\Services\UpdateReligion;
use Illuminate\Http\Request;

/**
 * @group Contact management
 *
 * @subgroup Religion
 */
class ContactReligionApiController extends ContactModuleApiController
{
    public function update(Request $request, string $vaultId, string $contactId)
    {
        (new UpdateReligion)->execute($this->baseData($request, $vaultId, $contactId) + [
            'religion_id' => $request->input('religion_id'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }
}
